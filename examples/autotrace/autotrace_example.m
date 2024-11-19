function yf = autotrace_example
% This example shows some simple MATLAB code that fits a line through a 
% cluster of data points. It does not include any instrumentation code.

% Copyright 2024 The MathWorks, Inc.

[x, y] = generate_data();
yf = best_fit_line(x,y);
end

function [x, y] = generate_data
% generate some random data
a = 1.5;
b = 0.8;
sigma = 5;
x = 1:100;
y = a * x + b + sigma * randn(1, 100);
end

function yf = best_fit_line(x, y)
% fit a line through points defined by inputs x and y
coefs = polyfit(x, y, 1);
yf = polyval(coefs , x);
end

