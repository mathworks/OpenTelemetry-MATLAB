function [x, y] = generate_data(n)
% example code for testing auto instrumentation

% Copyright 2024 The MathWorks, Inc.

% check input is valid
if ~(isnumeric(n) && isscalar(n))
    error("autotrace_examples:example1:generate_data:InvalidN", ...
        "Input must be a numeric scalar");
end

% generate some random data
a = 1.5;
b = 0.8;
sigma = 5;
x = 1:n;
y = a * x + b + sigma * randn(1, n);