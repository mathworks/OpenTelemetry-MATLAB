function response = webread_example
% This example shows how to propagate context (span ID and trace ID) 
% to another process when using webread.

% Copyright 2023-2024 The MathWorks, Inc.

% initialize tracing
runOnce(@initTracer);

% start a span
tr = opentelemetry.trace.getTracer("webread_example_tracer");
sp = startSpan(tr, "webread_example", SpanKind="client");
scope = makeCurrent(sp); %#ok<NASGU>

% inject context into header
carrier = opentelemetry.context.propagation.injectContext();

% call webread
url = "http://localhost:8800/webreadexample";
options = weboptions("HeaderFields", carrier.Headers); 
response = webread(url, options);

% everything seems to run fine if we get to this point
setStatus(sp, "ok", "status ok");  
end 

function initTracer
% set up global TracerProvider
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
tp = opentelemetry.sdk.trace.TracerProvider(Resource=resource);
setTracerProvider(tp);

% set up global propagator
prop = opentelemetry.trace.propagation.TraceContextPropagator();
setTextMapPropagator(prop);
end

% This helper ensures the input function is only run once
function runOnce(fh)
persistent hasrun
if isempty(hasrun)
    feval(fh);
    hasrun = 1;
end
end
