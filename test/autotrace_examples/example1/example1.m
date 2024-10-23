function yf = example1(n)
% example code for testing auto instrumentation. Input n is the number of
% data points.

% Copyright 2024 The MathWorks, Inc.

[x, y] = generate_data(n);
yf = best_fit_line(x,y);