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
testCase.TestData.traceState = "foo=00f067aa0ba902b7";
testCase.TestData.headers = ["traceparent", "00-" + testCase.TestData.traceId + ...
    "-" + testCase.TestData.spanId + "-01"; "tracestate", testCase.TestData.traceState];
testCase.TestData.baggageKeys = ["userId", "serverNode", "isProduction"];
testCase.TestData.baggageValues = ["alice", "DF28", "false"];
testCase.TestData.baggageHeaders = ["baggage", strjoin(strcat(testCase.TestData.baggageKeys, ...
    '=', testCase.TestData.baggageValues), ',')];
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
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "bar");
sp = startSpan(tr, "quux", Context=newcontext);
endSpan(sp);

% perform test comparisons
results = readJsonResults(testCase);
results = results{1};

% check trace and parent IDs
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.traceId), ...
    testCase.TestData.traceId);
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.parentSpanId), ...
    testCase.TestData.spanId);
% check trace state in span context
spancontext = getContext(sp);
verifyEqual(testCase, spancontext.TraceState, testCase.TestData.traceState);
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

% verify the extracted trace and span ID and trace state match the headers
verifyEqual(testCase, spancontext.TraceId, testCase.TestData.traceId);
verifyEqual(testCase, spancontext.SpanId, testCase.TestData.spanId);
verifyEqual(testCase, spancontext.TraceState, testCase.TestData.traceState);
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

% verify extracted trace and span IDs and trace state
verifyEqual(testCase, spancontext.TraceId, testCase.TestData.traceId);
verifyEqual(testCase, spancontext.SpanId, testCase.TestData.spanId);
verifyEqual(testCase, spancontext.TraceState, testCase.TestData.traceState);
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

%% testExtractBaggage: extracting baggage from HTTP header
function testExtractBaggage(testCase)

carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.TestData.baggageHeaders);
propagator = opentelemetry.baggage.propagation.BaggagePropagator();
context = opentelemetry.context.getCurrentContext();
newcontext = propagator.extract(carrier, context);
bag = opentelemetry.baggage.Context.extractBaggage(newcontext);
bag = bag.Entries;

baggagekeys = testCase.TestData.baggageKeys;
nkeys = length(baggagekeys);
for i = 1:nkeys
    verifyTrue(testCase, isKey(bag, baggagekeys(i)));
    verifyEqual(testCase, bag(baggagekeys(i)), testCase.TestData.baggageValues(i));
end

end

%% testInjectBaggage: injecting baggage into carrier
function testInjectBaggage(testCase)

% create a baggage
bag = opentelemetry.baggage.Baggage(dictionary(testCase.TestData.baggageKeys, ...
    testCase.TestData.baggageValues));

% insert baggage into context and inject
propagator = opentelemetry.baggage.propagation.BaggagePropagator();
context = opentelemetry.context.getCurrentContext();
newcontext = opentelemetry.baggage.Context.insertBaggage(context, bag);
carrier = opentelemetry.context.propagation.TextMapCarrier();
carrier = propagator.inject(carrier, newcontext);
headers = carrier.Headers;

% verify the baggage header
verifyEqual(testCase, headers, testCase.TestData.baggageHeaders);
end

%% testExtractContextBaggage: extractContext convenience function for baggage
function testExtractContextBaggage(testCase)
% set global propagator
propagator = opentelemetry.baggage.propagation.BaggagePropagator();
opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

% set up carrier and extract
carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.TestData.baggageHeaders);
context = opentelemetry.context.propagation.extractContext(carrier);
bag = opentelemetry.baggage.Context.extractBaggage(context);
bag = bag.Entries;

baggagekeys = testCase.TestData.baggageKeys;
nkeys = length(baggagekeys);
for i = 1:nkeys
    verifyTrue(testCase, isKey(bag, baggagekeys(i)));
    verifyEqual(testCase, bag(baggagekeys(i)), testCase.TestData.baggageValues(i));
end

end

%% testInjectContextBaggage: injectContext convenience function for baggage
function testInjectContextBaggage(testCase)
% set global propagator
propagator = opentelemetry.baggage.propagation.BaggagePropagator();
opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

% create a baggage and put it into the current context
bag = opentelemetry.baggage.Baggage(dictionary(testCase.TestData.baggageKeys, ...
    testCase.TestData.baggageValues));
context = opentelemetry.context.getCurrentContext();
newcontext = opentelemetry.baggage.Context.insertBaggage(context, bag);
token = setCurrentContext(newcontext); %#ok<NASGU>

% inject
carrier = opentelemetry.context.propagation.injectContext();
headers = carrier.Headers;

% verify the baggage header
verifyEqual(testCase, headers, testCase.TestData.baggageHeaders);
end

%% testCompositeExtract: extracting from HTTP header with a composite propagator
function testCompositeExtract(testCase)

carrier = opentelemetry.context.propagation.TextMapCarrier([testCase.TestData.headers; ...
    testCase.TestData.baggageHeaders]);

% define composite propagator
propagator = opentelemetry.context.propagation.CompositePropagator(...
    opentelemetry.trace.propagation.TraceContextPropagator, ...
    opentelemetry.baggage.propagation.BaggagePropagator);
context = opentelemetry.context.getCurrentContext();
newcontext = propagator.extract(carrier, context);

% extract baggage from context and verify
bag = opentelemetry.baggage.Context.extractBaggage(newcontext);
bag = bag.Entries;

baggagekeys = testCase.TestData.baggageKeys;
nkeys = length(baggagekeys);
for i = 1:nkeys
    verifyTrue(testCase, isKey(bag, baggagekeys(i)));
    verifyEqual(testCase, bag(baggagekeys(i)), testCase.TestData.baggageValues(i));
end

% start a span using extracted context as parent
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "bar");
sp = startSpan(tr, "quux", Context=newcontext);
endSpan(sp);

% perform test comparisons
results = readJsonResults(testCase);
results = results{1};

% check trace and parent IDs
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.traceId), ...
    testCase.TestData.traceId);
verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.parentSpanId), ...
    testCase.TestData.spanId);
% check trace state in span context
spancontext = getContext(sp);
verifyEqual(testCase, spancontext.TraceState, testCase.TestData.traceState);
end

%% testCompositeInject: injecting into carrier using composite propagator
function testCompositeInject(testCase)

% create composite propagator
propagator = opentelemetry.context.propagation.CompositePropagator(...
    opentelemetry.trace.propagation.TraceContextPropagator, ...
    opentelemetry.baggage.propagation.BaggagePropagator);

% start a span, make it current, and get the current context
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "foo");
sp = startSpan(tr, "bar");
scope = makeCurrent(sp); %#ok<NASGU>
context = opentelemetry.context.getCurrentContext();

% create baggage and insert into context
bag = opentelemetry.baggage.Baggage(dictionary(testCase.TestData.baggageKeys, ...
    testCase.TestData.baggageValues));
newcontext = opentelemetry.baggage.Context.insertBaggage(context, bag);

% inject context into carrier
carrier = opentelemetry.context.propagation.TextMapCarrier();
carrier = propagator.inject(carrier, newcontext);
headers = carrier.Headers;

endSpan(sp);

% verify number of fields are injected
verifyEqual(testCase, size(headers), [2 2]);

% verify the baggage header
baggagerow = find(headers(:,1) == "baggage");
verifyNotEmpty(testCase, baggagerow);
verifyEqual(testCase, headers(baggagerow, :), testCase.TestData.baggageHeaders);

results = readJsonResults(testCase);
results = results{1};

% verify traceparent field
traceparentrow = find(headers(:,1) == "traceparent");
verifyNotEmpty(testCase, traceparentrow);

% verify the traceparent field contains both the trace and span IDs
verifySubstring(testCase, headers(traceparentrow,2), string(results.resourceSpans.scopeSpans.spans.traceId));
verifySubstring(testCase, headers(traceparentrow,2), string(results.resourceSpans.scopeSpans.spans.spanId));
end

%% testExtractContextComposite: extractContext convenience function for composite extract
function testExtractContextComposite(testCase)
% set global propagator
propagator = opentelemetry.context.propagation.CompositePropagator(...
    opentelemetry.trace.propagation.TraceContextPropagator, ...
    opentelemetry.baggage.propagation.BaggagePropagator);
opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

% set up carrier and extract
carrier = opentelemetry.context.propagation.TextMapCarrier([testCase.TestData.headers; ...
    testCase.TestData.baggageHeaders]);
context = opentelemetry.context.propagation.extractContext(carrier);

% extract baggage and verify
bag = opentelemetry.baggage.Context.extractBaggage(context);
bag = bag.Entries;

baggagekeys = testCase.TestData.baggageKeys;
nkeys = length(baggagekeys);
for i = 1:nkeys
    verifyTrue(testCase, isKey(bag, baggagekeys(i)));
    verifyEqual(testCase, bag(baggagekeys(i)), testCase.TestData.baggageValues(i));
end

% extract span and verify
span = opentelemetry.trace.Context.extractSpan(context);
spancontext = getContext(span);

% verify extracted trace and span IDs and trace state
verifyEqual(testCase, spancontext.TraceId, testCase.TestData.traceId);
verifyEqual(testCase, spancontext.SpanId, testCase.TestData.spanId);
verifyEqual(testCase, spancontext.TraceState, testCase.TestData.traceState);
end

%% testInjectContextComposite: injectContext convenience function for composite injection
function testInjectContextComposite(testCase)
% set global propagator
propagator = opentelemetry.context.propagation.CompositePropagator(...
    opentelemetry.trace.propagation.TraceContextPropagator, ...
    opentelemetry.baggage.propagation.BaggagePropagator);
opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

% start a span and put it into the current context
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "foo");
sp = startSpan(tr, "bar");
scope = makeCurrent(sp); %#ok<NASGU>

% create a baggage and put it into the current context
bag = opentelemetry.baggage.Baggage(dictionary(testCase.TestData.baggageKeys, ...
    testCase.TestData.baggageValues));
context = opentelemetry.context.getCurrentContext();
newcontext = opentelemetry.baggage.Context.insertBaggage(context, bag);
token = setCurrentContext(newcontext); %#ok<NASGU>

% inject
carrier = opentelemetry.context.propagation.injectContext();
headers = carrier.Headers;

% verify the baggage header
baggagerow = find(headers(:,1) == "baggage");
verifyNotEmpty(testCase, baggagerow);
verifyEqual(testCase, headers(baggagerow,:), testCase.TestData.baggageHeaders);

% verify the injected traceparent contains the trace and span IDs
traceparentrow = find(headers(:,1) == "traceparent");
verifyNotEmpty(testCase, traceparentrow);
spancontext = getContext(sp);
verifySubstring(testCase, headers(traceparentrow,2), spancontext.TraceId);
verifySubstring(testCase, headers(traceparentrow,2), spancontext.SpanId);
end