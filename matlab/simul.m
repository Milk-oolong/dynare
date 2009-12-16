function simul(dr)
% function simul(dr)
% computes simulations
%  
% INPUTS
%   dr: structure of decision rules for stochastic simulations
%  
% OUTPUTS
%   ...
% ALGORITHM
%   ...
% SPECIAL REQUIREMENTS
%   none

% Copyright (C) 1996-2007 Dynare Team
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

global M_ options_ oo_ ys0_

if size(M_.lead_lag_incidence,2)-nnz(M_.lead_lag_incidence(M_.maximum_endo_lag+1,:)) > 0
    mess = ['DYNARE: error in model specification : variable ' M_.endo_names(find(M_.lead_lag_incidence(M_.maximum_lag+1,:)==0),:)] ;
    mess = [mess ' doesn''t appear as current variable.'] ; 
    error (mess) ;
end

options_ = set_default_option(options_,'periods',0);
if options_.periods == 0
    error('SIMUL: number of periods for the simulation isn''t specified')
end

if ~ options_.initval_file
    if ~isfield(options_,'datafile')
        make_ex_;
        make_y_;
    else
        read_data_;
    end
end

if isempty(options_.scalv) | options_.scalv == 0
    options_.scalv = oo_.steady_state ;
end

options_.scalv= 1 ;

if ~options_.block && ~options_.bytecode && options_.stack_solve_algo ~= 0
    error('SIMUL: for the moment, you must use stack_solve_algo=0 when not using block nor bytecode option')
end
if options_.block && ~options_.bytecode && (options_.stack_solve_algo == 0 || options_.stack_solve_algo == 5)
    error('SIMUL: for the moment, you must use stack_solve_algo={1,2,3,4} when using block without bytecode option')
end
if options_.block && options_.bytecode && options_.stack_solve_algo ~= 5
    error('SIMUL: for the moment, you must use stack_solve_algo=5 with block and bytecode option')
end

if(options_.block)
    if(options_.bytecode)
        oo_.endo_simul=bytecode('dynamic');
    else
        eval([M_.fname '_dynamic']);
    end;
else
    if M_.maximum_endo_lag ==1 & M_.maximum_endo_lead <= 1
        sim1 ;
    else
        simk ;
    end
end;

dyn2vec;

% 6/18/01 MJ added dyn2vec if 40 variables or less
% 01/16/03 MJ use dyn2vec whatever the number of variables
% 02/18/03 MJ added oo_.steady_state for calling simult
% 05/24/03 MJ added options_ and options_.periods