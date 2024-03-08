function a = parfor_example
% This example creates a trace through a parfor loop, by creating a span in
% each iteration and propagating context.
%
% Copyright 2024 The MathWorks, Inc.

% initialize tracing
runOnce(@initTracer);

% start the top level span and make it current
tr = opentelemetry.trace.getTracer("parfor_example"); 
sp = startSpan(tr, "main function"); 
scope = makeCurrent(sp); %#ok<*NASGU>

n = 80;
A = 500;
a = zeros(1,n);  % initialize the output
nworkers = 4;    % maximum number of workers

% propagate the current context by extracting and passing it in headers
carrier = opentelemetry.context.propagation.injectContext(); 
headers = carrier.Headers;

parfor (i = 1:n, nworkers)
    % parfor block needs its own initialization 
    runOnce(@initTracer);

    % extract context from headers and make it current
    carrier = opentelemetry.context.propagation.TextMapCarrier(headers);
    newcontext = opentelemetry.context.propagation.extractContext(carrier);
    scope_i = setCurrentContext(newcontext); 

    % start a span for this iteration
    tr_i = opentelemetry.trace.getTracer("parfor_example");     
    sp_i = startSpan(tr_i, "Iteration" + i);
    
    % compute the maximum eigenvalue of a random matrix
    a(i) = max(abs(eig(rand(A)))); 

    % end the scope and the span
    scope_i = []; 
    endSpan(sp_i);
end
end

function initTracer
% set up global TracerProvider
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
tp = opentelemetry.sdk.trace.TracerProvider(...
    opentelemetry.sdk.trace.SimpleSpanProcessor, Resource=resource);
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
