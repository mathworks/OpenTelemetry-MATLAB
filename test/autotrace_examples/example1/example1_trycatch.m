function yf = example1_trycatch(at, n)
% example code for testing auto instrumentation. This example should not
% use beginTrace method and instead should be called directly. 

% Copyright 2024 The MathWorks, Inc.

try
    [x, y] = generate_data(n);
    yf = best_fit_line(x,y);
catch ME
    handleError(at, ME);
end