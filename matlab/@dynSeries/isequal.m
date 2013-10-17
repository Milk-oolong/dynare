function C = isequal(A,B)

% Overloads ne (~=) operator.
%
% INPUTS 
%  o A      dynSeries object (T periods, N variables).
%  o B      dynSeries object (T periods, N variables).
%
% OUTPUTS 
%  o C      Integer scalar equal to zero or one.

% Copyright (C) 2013 Dynare Team
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

if nargin~=2
    error('dynSeries::isequal: I need exactly two input arguments!')
end

if ~(isa(A,'dynSeries') && isa(B,'dynSeries'))
    error('dynSeries::isequal: Both input arguments must be dynSeries objects!')
end

if ~isequal(A.nobs,B.nobs)
    C = 0;
    return
end

if ~isequal(A.vobs,B.vobs)
    C = 0;
    return
end

if ~isequal(A.freq,B.freq)
    C = 0;
    return
end

if ~isequal(A.init,B.init)
    C = 0;
    return
end

if ~isequal(A.name,B.name)
    warning('dynSeries::isequal: Both input arguments do not have the same variables!')
end

if ~isequal(A.tex,B.tex)
    warning('dynSeries::isequal: Both input arguments do not have the same tex names!')
end

C = isequal(A.data, B.data);