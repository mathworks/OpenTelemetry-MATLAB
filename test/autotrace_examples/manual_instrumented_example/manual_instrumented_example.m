function yf = manual_instrumented_example(n)
% Example code for testing auto and manual instrumentation together. 
% Input n is the number of data points.

% Copyright 2024 The MathWorks, Inc.

% add an attribute about input
ctx = opentelemetry.context.getCurrentContext;
sp = opentelemetry.trace.Context.extractSpan(ctx);
setAttributes(sp, "DataSize", n);

[x, y] = generate_data(n);
yf = best_fit_line(x,y);