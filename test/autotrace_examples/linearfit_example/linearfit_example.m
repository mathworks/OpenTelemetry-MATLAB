function yf = linearfit_example(n)
% Example code for testing auto instrumentation. Input n is the number of
% data points.

% Copyright 2024 The MathWorks, Inc.

[x, y] = generate_data(n);
yf = best_fit_line(x,y);