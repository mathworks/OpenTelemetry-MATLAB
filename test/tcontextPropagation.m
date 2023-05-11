function tests = tcontextPropagation
% tests for injecting and extracting context from HTTP headers
%
% Copyright 2023 The MathWorks, Inc.

tests = functiontests(localfunctions);
end

function setupOnce(testCase)
commonSetupOnce(testCase);

% simulate an HTTP header with relevant fields, used for extraction 
testCase.TestData.traceId = "0af7651916cd43dd8448eb211c80319c";
testCase.TestData.spanId = "00f067aa0ba902b7";
testCase.TestData.headers = ["traceparent", "00-" + testCase.TestData.traceId + ...
    "-" + testCase.TestData.spanId + "-01"; "tracestate", "foo=00f067aa0ba902b7"];
end

function setup(testCase)
commonSetup(testCase);
end

function teardown(testCase)
commonTeardown(testCase);
end

%% testExtract: extracting context from HTTP header
function testExtract(testCase)

carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.TestData.headers);
propagator = opentelemetry.trace.propagation.TraceContextPropagator();
context = opentelemetry.context.getCurrentContext();
newcontext = propagator.extract(carrier, context);
token = setCurrentContext(newcontext); %#ok<NASGU>
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "bar");
sp = startSpan(tr, "quux");
endSpan(sp);

% perform test comparisons
results = readJsonResults(testCase);
results = results{1};

% check trace and parent IDs
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.traceId), ...
    testCase.TestData.traceId);
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.parentSpanId), ...
    testCase.TestData.spanId);
end

%% testExplicitContext: extracting context from HTTP header, and then extracting span context
% for use as explicit parent
function testExplicitContext(testCase)

carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.TestData.headers);
propagator = opentelemetry.trace.propagation.TraceContextPropagator();
context = opentelemetry.context.getCurrentContext();
newcontext = propagator.extract(carrier, context);

% extract span context from extracted context
parent = opentelemetry.trace.Context.extractSpan(newcontext);
parentcontext = getContext(parent);

% start and end child span, passing in parent span context
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "bar");
sp = startSpan(tr, "quux", Context=parentcontext);
endSpan(sp);

% perform test comparisons
results = readJsonResults(testCase);
results = results{1};

% check trace and parent IDs
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.traceId), ...
    testCase.TestData.traceId);
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.parentSpanId), ...
    testCase.TestData.spanId);
end

%% testInject: injecting context into carrier
function testInject(testCase)

% start a span and make it current
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "foo");
sp = startSpan(tr, "bar");
scope = makeCurrent(sp); %#ok<NASGU>

% inject the current context
propagator = opentelemetry.trace.propagation.TraceContextPropagator();
context = opentelemetry.context.getCurrentContext();
carrier = opentelemetry.context.propagation.TextMapCarrier();
carrier = propagator.inject(carrier, context);
headers = carrier.Headers;

endSpan(sp);

% perform test comparisons
results = readJsonResults(testCase);
results = results{1};

% verify only one field is injected
verifyEqual(testCase, size(headers), [1 2]);
verifyEqual(testCase, headers(1,1), "traceparent");

% verify the traceparent field contains both the trace and span IDs
verifySubstring(testCase, headers(1,2), string(results.resourceSpans.scopeSpans.spans.traceId));
verifySubstring(testCase, headers(1,2), string(results.resourceSpans.scopeSpans.spans.spanId));
end

%% testGetSetTextMapPropagator: setting and getting global instance of TextMapPropagator
function testGetSetTextMapPropagator(testCase)

% create a propagator and set it as global instance
propagator = opentelemetry.trace.propagation.TraceContextPropagator();
opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

% clear the propagator
clear("propagator");

% get the global instance of propagator
p = opentelemetry.context.propagation.Propagator.getTextMapPropagator();
carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.TestData.headers);
context = opentelemetry.context.Context();
newcontext = p.extract(carrier, context);
span = opentelemetry.trace.Context.extractSpan(newcontext);
spancontext = getContext(span);

% verify the extracted trace and span ID match the headers
verifyEqual(testCase, spancontext.TraceId, testCase.TestData.traceId);
verifyEqual(testCase, spancontext.SpanId, testCase.TestData.spanId);
end

%% testExtractContext: extractContext convenience function
% extractContext uses global propagator and current context
function testExtractContext(testCase)
% set global propagator
propagator = opentelemetry.trace.propagation.TraceContextPropagator();
opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

% set up carrier and extract
carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.TestData.headers);
context = opentelemetry.context.propagation.extractContext(carrier);
span = opentelemetry.trace.Context.extractSpan(context);
spancontext = getContext(span);

% verify extracted trace and span IDs
verifyEqual(testCase, spancontext.TraceId, testCase.TestData.traceId);
verifyEqual(testCase, spancontext.SpanId, testCase.TestData.spanId);
end

%% testInjectContext: injectContext convenience function
% injectContext uses global propagator and current context
function testInjectContext(testCase)
% set global propagator
propagator = opentelemetry.trace.propagation.TraceContextPropagator();
opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

% start a span and make it current
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "foo");
sp = startSpan(tr, "bar");
spancontext = getContext(sp);
scope = makeCurrent(sp); %#ok<NASGU>

% inject
carrier = opentelemetry.context.propagation.injectContext();
headers = carrier.Headers;

% verify the injected traceparent contains the trace and span IDs
verifySubstring(testCase, headers(1,2), spancontext.TraceId);
verifySubstring(testCase, headers(1,2), spancontext.SpanId);
end