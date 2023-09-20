function response = mymagic(request)
% Web request handler function that takes context information (trace ID and span ID)
% from incoming request and set as current context
%
% Copyright 2023 The MathWorks, Inc.

% initialize tracing
runOnce(@initTracer);

% extract context passed from header
carrier = opentelemetry.context.propagation.TextMapCarrier(request.Headers);
newcontext = opentelemetry.context.propagation.extractContext(carrier);
scope = setCurrentContext(newcontext); %#ok<NASGU>

% start a span
tr = opentelemetry.trace.getTracer("MATLABTracer");
sp = startSpan(tr, "mymagic", "SpanKind", "server");

sz = double(request.Body);
magicsquare = magic(request.Body);  % generate the magic square
setAttributes(sp, "input", sz, "output", magicsquare);

% convert magic square to char
magicsquare_char = char(strjoin(string(magicsquare)));

% return a response
response = struct('ApiVersion', [1 0 0], ...
    'HttpCode', 200, ...
    'HttpMessage', 'OK', ...
    'Headers', {{ ...
    'Server' 'MATLABMagicFunction'; ...
    'X-Magic-Square-Size' sprintf('%d', sz); ...
    'Content-Type' 'text/plain'; ...
    }},...
    'Body', uint8(magicsquare_char));

% everything seems to run fine if we get to this point
setStatus(sp, "ok", "status ok");  
end

function initTracer
% set up global TracerProvider
tp = opentelemetry.sdk.trace.TracerProvider();
setTracerProvider(tp);

% set up global propagator
prop = opentelemetry.trace.propagation.TraceContextPropagator();
setTextMapPropagator(prop);
end

% Thie helper ensures the input function is only run once
function runOnce(fh)
persistent hasrun
if isempty(hasrun)
    feval(fh);
    hasrun = 1;
end
end
