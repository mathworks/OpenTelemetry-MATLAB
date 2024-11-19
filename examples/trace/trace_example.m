function yf = trace_example
% This example creates spans to form a trace to instrument some simple
% MATLAB code that fits a line through a cluster of data points. 

% Copyright 2023-2024 The MathWorks, Inc.

% initialize tracing during first run
runOnce(@initTracer);

% start the top level span and make it current
tr = opentelemetry.trace.getTracer("trace_example");
sp = startSpan(tr, "trace_example");
scope = makeCurrent(sp); %#ok<*NASGU>

[x, y] = generate_data();
yf = best_fit_line(x,y);
end

function [x, y] = generate_data
% generate some random data
tr = opentelemetry.trace.getTracer("trace_example");
sp = startSpan(tr, "generate_data");
scope = makeCurrent(sp); 

a = 1.5;
b = 0.8;
sigma = 5;
x = 1:100;
y = a * x + b + sigma * randn(1, 100);
end

function yf = best_fit_line(x, y)
% fit a line through points defined by inputs x and y
tr = opentelemetry.trace.getTracer("trace_example");
sp = startSpan(tr, "best_fit_line");
scope = makeCurrent(sp); 

coefs = polyfit(x, y, 1);
yf = polyval(coefs , x);
end

function initTracer
% set up global TracerProvider
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
tp = opentelemetry.sdk.trace.TracerProvider(Resource=resource);
setTracerProvider(tp);
end

% This helper ensures the input function is only run once
function runOnce(fh)
persistent hasrun
if isempty(hasrun)
    feval(fh);
    hasrun = 1;
end
end
