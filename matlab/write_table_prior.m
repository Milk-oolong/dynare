function write_table_prior(lb, ub, DynareOptions, ModelInfo, BayesInfo, EstimationInfo)
    
% This routine builds a latex table with some descriptive statistics about the prior distribution. 

% Copyright (C) 2015 Dynare Team
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

PriorNames = { 'Beta' , 'Gamma' , 'Gaussian' , 'Inverted Gamma' , 'Uniform' , 'Inverted Gamma -- 2' };

if size(ModelInfo.param_names,1)==size(ModelInfo.param_names_tex,1)% All the parameters have a TeX name.
    fidTeX = fopen('priors_data.tex','w+');
    fprintf(fidTeX,'%% TeX-table generated by Dynare.\n');
    fprintf(fidTeX,'%% Prior Information\n');
    fprintf(fidTeX,['%% ' datestr(now,0)]);
    fprintf(fidTeX,' \n');
    fprintf(fidTeX,' \n');
    fprintf(fidTeX,'\\begin{center}\n');
    fprintf(fidTeX,'\\begin{longtable}{l|cccccccc} \n');
    fprintf(fidTeX,'\\caption{Prior information (parameters)}\\\\\n ');
    fprintf(fidTeX,'\\label{Table:Prior}\\\\\n');
    fprintf(fidTeX,'\\hline\\hline \\\\ \n');
    fprintf(fidTeX,'  & Prior distribution & Prior mean & Prior mode & Prior s.d. & Lower Bound & Upper Bound & LB Untrunc. 80\\%% HPDI & UB Untrunc. 80\\%% HPDI  \\\\ \n');
    fprintf(fidTeX,'\\hline \\endfirsthead \n');
    fprintf(fidTeX,'\\caption{(continued)}\\\\\n ');
    fprintf(fidTeX,'\\hline\\hline \\\\ \n');
    fprintf(fidTeX,'  & Prior distribution & Prior mean & Prior mode  & Prior s.d. & Lower Bound & Upper Bound & LB Untrunc.  80\\%% HPDI & UB Untrunc. 80\\%% HPDI  \\\\ \n');
    fprintf(fidTeX,'\\hline \\endhead \n');
    fprintf(fidTeX,'\\hline \\multicolumn{9}{r}{(Continued on next page)} \\\\ \\hline \\endfoot \n');
    fprintf(fidTeX,'\\hline \\hline \\endlastfoot \n');
    % Column 1: a string for the name of the prior distribution.
    % Column 2: the prior mean.
    % Column 3: the prior mode.
    % Column 4: the prior standard deviation.
    % Column 5: the lower bound of the prior density support.
    % Column 6: the upper bound of the prior density support.
    % Column 7: the lower bound of the interval containing 80% of the prior mass.
    % Column 8: the upper bound of the interval containing 80% of the prior mass.
    prior_trunc_backup = DynareOptions.prior_trunc ;
    DynareOptions.prior_trunc = (1-DynareOptions.prior_interval)/2 ;
    PriorIntervals = prior_bounds(BayesInfo,DynareOptions) ;
    DynareOptions.prior_trunc = prior_trunc_backup ;
    for i=1:size(BayesInfo.name,1)
        [tmp,TexName] = get_the_name(i,1,ModelInfo,EstimationInfo,DynareOptions);
        PriorShape = PriorNames{ BayesInfo.pshape(i) };
        PriorMean = BayesInfo.p1(i);
        PriorMode = BayesInfo.p5(i);
        PriorStandardDeviation = BayesInfo.p2(i);
        switch BayesInfo.pshape(i)
          case { 1 , 5 }
            LowerBound = BayesInfo.p3(i);
            UpperBound = BayesInfo.p4(i);
            if ~isinf(lb(i))
                LowerBound=max(LowerBound,lb(i));
            end
            if ~isinf(ub(i))
                UpperBound=min(UpperBound,ub(i));
            end
          case { 2 , 4 , 6 }
            LowerBound = BayesInfo.p3(i);
            if ~isinf(lb(i))
                LowerBound=max(LowerBound,lb(i));
            end
            if ~isinf(ub(i))
                UpperBound=ub(i);
            else
                UpperBound = '$\infty$';
            end
          case 3
            if isinf(BayesInfo.p3(i)) && isinf(lb(i))
                LowerBound = '$-\infty$';
            else
                LowerBound = BayesInfo.p3(i);
                if ~isinf(lb(i))
                    LowerBound=max(LowerBound,lb(i));
                end
            end
            if isinf(BayesInfo.p4(i)) && isinf(ub(i))
                UpperBound = '$\infty$';
            else
                UpperBound = BayesInfo.p4(i);
                if ~isinf(ub(i))
                    UpperBound=min(UpperBound,ub(i));
                end
            end
          otherwise
            error('get_prior_info:: Dynare bug!')
        end
        format_string = build_format_string(PriorMode, PriorStandardDeviation,LowerBound,UpperBound);
        fprintf(fidTeX,format_string, ...
                TexName, ...
                PriorShape, ...
                PriorMean, ...
                PriorMode, ...
                PriorStandardDeviation, ...
                LowerBound, ...
                UpperBound, ...
                PriorIntervals.lb(i), ...
                PriorIntervals.ub(i) );
    end
    fprintf(fidTeX,'\\end{longtable}\n ');    
    fprintf(fidTeX,'\\end{center}\n');
    fprintf(fidTeX,'%% End of TeX file.\n');
    fclose(fidTeX);
end

function format_string = build_format_string(PriorMode,PriorStandardDeviation,LowerBound,UpperBound)
format_string = ['%s & %s & %6.4f &'];
if isnan(PriorMode)
    format_string = [ format_string , ' %s &'];
else
    format_string = [ format_string , ' %6.4f &'];
end
if ~isnumeric(PriorStandardDeviation)
    format_string = [ format_string , ' %s &'];
else
    format_string = [ format_string , ' %6.4f &'];
end
if ~isnumeric(LowerBound)
    format_string = [ format_string , ' %s &'];
else
    format_string = [ format_string , ' %6.4f &'];
end
if ~isnumeric(UpperBound)
    format_string = [ format_string , ' %s &'];
else
    format_string = [ format_string , ' %6.4f &'];
end
format_string = [ format_string , ' %6.4f & %6.4f \\\\ \n'];