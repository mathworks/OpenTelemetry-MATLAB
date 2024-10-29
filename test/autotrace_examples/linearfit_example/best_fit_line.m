function yf = best_fit_line(x, y)
% Fit a straight line on input data

% Copyright 2024 The MathWorks, Inc.

coefs = polyfit(x, y, 1);
yf = polyval(coefs , x);
