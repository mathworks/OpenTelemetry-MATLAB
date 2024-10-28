function yf = best_fit_line(x, y)
% Fit a straight line on input data and manually start and end two spans.

% Copyright 2024 The MathWorks, Inc.

tr = opentelemetry.trace.getTracer("ManualInstrument");

sp1 = startSpan(tr, "polyfit");
coefs = polyfit(x, y, 1);
endSpan(sp1);

sp2 = startSpan(tr, "polyval");
yf = polyval(coefs , x);
endSpan(sp2);
