function [x, y] = generate_data(n)
% Generate random data with n data points

% Copyright 2024 The MathWorks, Inc.

% check input is valid
if ~(isnumeric(n) && isscalar(n))
    error("autotrace_examples:linearfit_example:generate_data:InvalidN", ...
        "Input must be a numeric scalar");
end

% generate some random data
a = 1.5;
b = 0.8;
sigma = 5;
x = 1:n;
y = a * x + b + sigma * randn(1, n);