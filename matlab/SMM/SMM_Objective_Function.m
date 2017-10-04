function [fval,info,exit_flag,moments_difference,modelMoments,junk1,junk2,Model,DynareOptions,SMMinfo,DynareResults]...
    = SMM_Objective_Function(xparam1,DynareDataset,DynareOptions,Model,EstimatedParameters,SMMinfo,BoundsInfo,DynareResults)
% [fval,info,exit_flag,moments_difference,modelMoments,junk1,junk2,Model,DynareOptions,SMMinfo,DynareResults]...
%    = SMM_Objective_Function(xparam1,DynareDataset,DynareOptions,Model,EstimatedParameters,SMMinfo,BoundsInfo,DynareResults)
% This function evaluates the objective function for SMM estimation
%
% INPUTS
%   o xparam1:                  initial value of estimated parameters as returned by set_prior()
%   o DynareDataset:            data after required transformation
%   o DynareOptions:            Matlab's structure describing the options (initialized by dynare, see @ref{options_}).
%   o Model                     Matlab's structure describing the Model (initialized by dynare, see @ref{M_}).          
%   o EstimatedParameters:      Matlab's structure describing the estimated_parameters (initialized by dynare, see @ref{estim_params_}).
%   o SMMInfo                   Matlab's structure describing the SMM settings (initialized by dynare, see @ref{bayesopt_}).
%   o BoundsInfo                Matlab's structure containing prior bounds
%   o DynareResults             Matlab's structure gathering the results (initialized by dynare, see @ref{oo_}).
%
% OUTPUTS
%   o fval:                     value of the quadratic form of the moment difference
%   o moments_difference:       [numMom x 1] vector with difference of empirical and model moments
%   o modelMoments:             [numMom x 1] vector with model moments
%   o exit_flag:                0 if no error, 1 of error
%   o info:                     vector storing error code and penalty 
%   o Model:                    Matlab's structure describing the Model (initialized by dynare, see @ref{M_}).
%   o DynareOptions:            Matlab's structure describing the options (initialized by dynare, see @ref{options_}).
%   o SMMinfo:                  Matlab's structure describing the SMM parameter options (initialized by dynare, see @ref{SMMinfo_}).
%   o DynareResults:            Matlab's structure gathering the results (initialized by dynare, see @ref{oo_}).

% SPECIAL REQUIREMENTS
%   none

% Copyright (C) 2013-17 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.


global objective_function_penalty_base

% Initialization of the returned variables and others...
fval        = NaN;
exit_flag   = 1;
info        = 0;
junk2       = [];
junk1       = [];
moments_difference=NaN(SMMinfo.numMom,1);
modelMoments=NaN(SMMinfo.numMom,1);
%------------------------------------------------------------------------------
% 1. Get the structural parameters & define penalties
%------------------------------------------------------------------------------

% Return, with endogenous penalty, if some parameters are smaller than the lower bound of the parameters.
if ~isequal(DynareOptions.mode_compute,1) && any(xparam1<BoundsInfo.lb)
    k = find(xparam1<BoundsInfo.lb);
    fval = Inf;
    exit_flag = 0;
    info(1) = 41;
    info(4)= sum((BoundsInfo.lb(k)-xparam1(k)).^2);
    return
end

% Return, with endogenous penalty, if some parameters are greater than the upper bound of the parameters.
if ~isequal(DynareOptions.mode_compute,1) && any(xparam1>BoundsInfo.ub)
    k = find(xparam1>BoundsInfo.ub);
    fval = Inf;
    exit_flag = 0;
    info(1) = 42;
    info(4)= sum((xparam1(k)-BoundsInfo.ub(k)).^2);
    return
end

% Set all parameters
Model = set_all_parameters(xparam1,EstimatedParameters,Model);

% Test if Q is positive definite.
if ~issquare(Model.Sigma_e) || EstimatedParameters.ncx || isfield(EstimatedParameters,'calibrated_covariances')
    [Q_is_positive_definite, penalty] = ispd(Model.Sigma_e(EstimatedParameters.Sigma_e_entries_to_check_for_positive_definiteness,EstimatedParameters.Sigma_e_entries_to_check_for_positive_definiteness));
    if ~Q_is_positive_definite
        fval = Inf;
        exit_flag = 0;
        info(1) = 43;
        info(4) = penalty;
        return
    end
    if isfield(EstimatedParameters,'calibrated_covariances')
        correct_flag=check_consistency_covariances(Model.Sigma_e);
        if ~correct_flag
            penalty = sum(Model.Sigma_e(EstimatedParameters.calibrated_covariances.position).^2);
            fval = Inf;
            exit_flag = 0;
            info(1) = 71;
            info(4) = penalty;
            return
        end
    end
end

%------------------------------------------------------------------------------
% 2. call resol to compute steady state and model solution
%------------------------------------------------------------------------------

[dr_dynare_state_space,info,Model,DynareOptions,DynareResults] = resol(0,Model,DynareOptions,DynareResults);

% Return, with endogenous penalty when possible, if dynare_resolve issues an error code (defined in resol).
if info(1)
    if info(1) == 3 || info(1) == 4 || info(1) == 5 || info(1)==6 ||info(1) == 19 ||...
                info(1) == 20 || info(1) == 21 || info(1) == 23 || info(1) == 26 || ...
                info(1) == 81 || info(1) == 84 ||  info(1) == 85 ||  info(1) == 86
        %meaningful second entry of output that can be used
        fval = Inf;
        info(4) = info(2);
        exit_flag = 0;
        return
    else
        fval = Inf;
        info(4) = 0.1;
        exit_flag = 0;
        return
    end
end

% % check endogenous prior restrictions
% info=endogenous_prior_restrictions(T,R,Model,DynareOptions,DynareResults);
% if info(1)
%     fval = Inf;
%     info(4)=info(2);
%     exit_flag = 0;
%     return
% end

%------------------------------------------------------------------------------
% 3. Compute Moments of the model solution for normal innovations
%------------------------------------------------------------------------------
% create shock series with correct covariance matrix from iid standard
% normal shocks
i_exo_var = setdiff([1:Model.exo_nbr],find(diag(Model.Sigma_e) == 0 )); %find singular entries in covariance
chol_S = chol(Model.Sigma_e(i_exo_var,i_exo_var));
scaled_shock_series=zeros(size(DynareResults.smm.shock_series)); %initialize
scaled_shock_series(:,i_exo_var) = DynareResults.smm.shock_series(:,i_exo_var)*chol_S; %set non-zero entries


%% simulate series
y_sim = simult_(dr_dynare_state_space.ys,dr_dynare_state_space,scaled_shock_series,DynareOptions.order);

if any(any(isnan(y_sim))) || any(any(isinf(y_sim)))
    fval = Inf;
    info(1)=180;
    info(4) = 0.1;
    exit_flag = 0;
    return
end
y_sim_after_burnin = y_sim(SMMinfo.varsindex,end-DynareOptions.smm.long:end)';
autolag=max(DynareOptions.smm.autolag);
if DynareOptions.smm.centeredmoments
   y_sim_after_burnin=bsxfun(@minus,y_sim_after_burnin,mean(y_sim_after_burnin,1)); 
end
[modelMoments, E_y, E_yy, autoE_yy] = moments_GMM_SMM_Data(y_sim_after_burnin,DynareOptions);
% write centered and uncentered simulated moments to results
DynareResults.smm.unconditionalmoments.E_y=E_y;
DynareResults.smm.unconditionalmoments.E_yy=E_yy;
DynareResults.smm.unconditionalmoments.autoE_yy=autoE_yy;
DynareResults.smm.unconditionalmoments.Var_y=E_yy-E_y*E_y';
DynareResults.smm.unconditionalmoments.Cov_y=autoE_yy-repmat(E_y*E_y',[1 1 autolag]);

%------------------------------------------------------------------------------
% 4. Compute quadratic target function using weighting matrix W
%------------------------------------------------------------------------------
moments_difference = DynareResults.smm.datamoments.momentstomatch-modelMoments;
fval = moments_difference'*DynareResults.smm.W*moments_difference;

if DynareOptions.smm.penalized_estimator
    fval=fval+(xparam1-SMMinfo.p1)'/diag(SMMinfo.p2)*(xparam1-SMMinfo.p1);
end
end