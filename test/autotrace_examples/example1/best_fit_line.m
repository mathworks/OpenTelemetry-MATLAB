function yf = best_fit_line(x, y)
% example code for testing auto instrumentation

% Copyright 2024 The MathWorks, Inc.

coefs = polyfit(x, y, 1);
yf = polyval(coefs , x);
