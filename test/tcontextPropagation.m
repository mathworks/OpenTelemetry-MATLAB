classdef tcontextPropagation < matlab.unittest.TestCase
    % tests for injecting and extracting context from HTTP headers

    % Copyright 2023 The MathWorks, Inc.

    properties
        OtelConfigFile
        OtelRoot
        JsonFile
        PidFile
        Otelcol
        ListPid
        ReadPidList
        ExtractPid
        Sigint
        Sigterm
        TraceId
        SpanId
        TraceState
        Headers
        BaggageKeys
        BaggageValues
        BaggageHeaders
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            commonSetupOnce(testCase);

            % simulate an HTTP header with relevant fields, used for extraction
            testCase.TraceId = "0af7651916cd43dd8448eb211c80319c";
            testCase.SpanId = "00f067aa0ba902b7";
            testCase.TraceState = "foo=00f067aa0ba902b7";
            testCase.Headers = ["traceparent", "00-" + testCase.TraceId + ...
                "-" + testCase.SpanId + "-01"; "tracestate", testCase.TraceState];
            testCase.BaggageKeys = ["userId", "serverNode", "isProduction"];
            testCase.BaggageValues = ["alice", "DF28", "false"];
            testCase.BaggageHeaders = ["baggage", strjoin(strcat(testCase.BaggageKeys, ...
                '=', testCase.BaggageValues), ',')];
        end
    end

    methods (TestMethodSetup)
        function setup(testCase)
            commonSetup(testCase);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            commonTeardown(testCase);
        end
    end

    methods (Test)
        function testExtract(testCase)
            % testExtract: extracting context from HTTP header
            carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.Headers);
            propagator = opentelemetry.trace.propagation.TraceContextPropagator();
            newcontext = propagator.extract(carrier);
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "bar");
            sp = startSpan(tr, "quux", Context=newcontext);
            pause(1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check trace and parent IDs
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.traceId), ...
                testCase.TraceId);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.parentSpanId), ...
                testCase.SpanId);
            % check trace state in span context
            spancontext = getSpanContext(sp);
            verifyEqual(testCase, spancontext.TraceState, testCase.TraceState);
        end

        function testInject(testCase)
            % testInject: injecting context into carrier

            % start a span and make it current
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            scope = makeCurrent(sp); %#ok<NASGU>

            % inject the current context
            propagator = opentelemetry.trace.propagation.TraceContextPropagator();
            carrier = opentelemetry.context.propagation.TextMapCarrier();
            carrier = propagator.inject(carrier);
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

        function testGetSetTextMapPropagator(testCase)
            % testGetSetTextMapPropagator: setting and getting global instance of TextMapPropagator

            % create a propagator and set it as global instance
            propagator = opentelemetry.trace.propagation.TraceContextPropagator();
            opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

            % clear the propagator
            clear("propagator");

            % get the global instance of propagator
            p = opentelemetry.context.propagation.Propagator.getTextMapPropagator();
            carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.Headers);
            context = opentelemetry.context.Context();
            newcontext = p.extract(carrier, context);
            span = opentelemetry.trace.Context.extractSpan(newcontext);
            spancontext = getSpanContext(span);

            % verify the extracted trace and span ID and trace state match the headers
            verifyEqual(testCase, spancontext.TraceId, testCase.TraceId);
            verifyEqual(testCase, spancontext.SpanId, testCase.SpanId);
            verifyEqual(testCase, spancontext.TraceState, testCase.TraceState);
        end

        function testExtractContext(testCase)
            % testExtractContext: extractContext convenience function
            % extractContext uses global propagator and current context

            % set global propagator
            propagator = opentelemetry.trace.propagation.TraceContextPropagator();
            opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

            % set up carrier and extract
            carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.Headers);
            context = opentelemetry.context.propagation.extractContext(carrier);
            span = opentelemetry.trace.Context.extractSpan(context);
            spancontext = getSpanContext(span);

            % verify extracted trace and span IDs and trace state
            verifyEqual(testCase, spancontext.TraceId, testCase.TraceId);
            verifyEqual(testCase, spancontext.SpanId, testCase.SpanId);
            verifyEqual(testCase, spancontext.TraceState, testCase.TraceState);
        end

        function testInjectContext(testCase)
            % testInjectContext: injectContext convenience function
            % injectContext uses global propagator and current context

            % set global propagator
            propagator = opentelemetry.trace.propagation.TraceContextPropagator();
            opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

            % start a span and make it current
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            spancontext = getSpanContext(sp);
            scope = makeCurrent(sp); %#ok<NASGU>

            % inject
            carrier = opentelemetry.context.propagation.injectContext();
            headers = carrier.Headers;
            endSpan(sp);

            % verify the injected traceparent contains the trace and span IDs
            verifySubstring(testCase, headers(1,2), spancontext.TraceId);
            verifySubstring(testCase, headers(1,2), spancontext.SpanId);
        end

        function testExtractBaggage(testCase)
            % testExtractBaggage: extracting baggage from HTTP header

            carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.BaggageHeaders);
            propagator = opentelemetry.baggage.propagation.BaggagePropagator();
            newcontext = propagator.extract(carrier);
            bag = opentelemetry.baggage.Context.extractBaggage(newcontext);
            bag = bag.Entries;

            baggagekeys = testCase.BaggageKeys;
            nkeys = length(baggagekeys);
            for i = 1:nkeys
                verifyTrue(testCase, isKey(bag, baggagekeys(i)));
                verifyEqual(testCase, bag(baggagekeys(i)), testCase.BaggageValues(i));
            end

        end

        function testInjectBaggage(testCase)
            % testInjectBaggage: injecting baggage into carrier

            % create a baggage
            bag = opentelemetry.baggage.Baggage(dictionary(testCase.BaggageKeys, ...
                testCase.BaggageValues));

            % insert baggage into context and inject
            propagator = opentelemetry.baggage.propagation.BaggagePropagator();
            context = opentelemetry.context.getCurrentContext();
            newcontext = opentelemetry.baggage.Context.insertBaggage(context, bag);
            carrier = opentelemetry.context.propagation.TextMapCarrier();
            carrier = propagator.inject(carrier, newcontext);
            headers = carrier.Headers;

            % verify the baggage header
            verifyEqual(testCase, headers, testCase.BaggageHeaders);
        end

        function testExtractContextBaggage(testCase)
            % testExtractContextBaggage: extractContext convenience function for baggage

            % set global propagator
            propagator = opentelemetry.baggage.propagation.BaggagePropagator();
            opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

            % set up carrier and extract
            carrier = opentelemetry.context.propagation.TextMapCarrier(testCase.BaggageHeaders);
            context = opentelemetry.context.propagation.extractContext(carrier);
            bag = opentelemetry.baggage.Context.extractBaggage(context);
            bag = bag.Entries;

            baggagekeys = testCase.BaggageKeys;
            nkeys = length(baggagekeys);
            for i = 1:nkeys
                verifyTrue(testCase, isKey(bag, baggagekeys(i)));
                verifyEqual(testCase, bag(baggagekeys(i)), testCase.BaggageValues(i));
            end

        end

        function testInjectContextBaggage(testCase)
            % testInjectContextBaggage: injectContext convenience function for baggage

            % set global propagator
            propagator = opentelemetry.baggage.propagation.BaggagePropagator();
            opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

            % create a baggage and put it into the current context
            bag = opentelemetry.baggage.Baggage(dictionary(testCase.BaggageKeys, ...
                testCase.BaggageValues));
            context = opentelemetry.context.getCurrentContext();
            newcontext = opentelemetry.baggage.Context.insertBaggage(context, bag);
            token = setCurrentContext(newcontext); %#ok<NASGU>

            % inject
            carrier = opentelemetry.context.propagation.injectContext();
            headers = carrier.Headers;

            % verify the baggage header
            verifyEqual(testCase, headers, testCase.BaggageHeaders);
        end

        function testCompositeExtract(testCase)
            % testCompositeExtract: extracting from HTTP header with a composite propagator

            carrier = opentelemetry.context.propagation.TextMapCarrier([testCase.Headers; ...
                testCase.BaggageHeaders]);

            % define composite propagator
            propagator = opentelemetry.context.propagation.CompositePropagator(...
                opentelemetry.trace.propagation.TraceContextPropagator, ...
                opentelemetry.baggage.propagation.BaggagePropagator);
            newcontext = propagator.extract(carrier);

            % extract baggage from context and verify
            bag = opentelemetry.baggage.Context.extractBaggage(newcontext);
            bag = bag.Entries;

            baggagekeys = testCase.BaggageKeys;
            nkeys = length(baggagekeys);
            for i = 1:nkeys
                verifyTrue(testCase, isKey(bag, baggagekeys(i)));
                verifyEqual(testCase, bag(baggagekeys(i)), testCase.BaggageValues(i));
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
                testCase.TraceId);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.parentSpanId), ...
                testCase.SpanId);
            % check trace state in span context
            spancontext = getSpanContext(sp);
            verifyEqual(testCase, spancontext.TraceState, testCase.TraceState);
        end

        function testCompositeInject(testCase)
            % testCompositeInject: injecting into carrier using composite propagator

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
            bag = opentelemetry.baggage.Baggage(dictionary(testCase.BaggageKeys, ...
                testCase.BaggageValues));
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
            verifyEqual(testCase, headers(baggagerow, :), testCase.BaggageHeaders);

            results = readJsonResults(testCase);
            results = results{1};

            % verify traceparent field
            traceparentrow = find(headers(:,1) == "traceparent");
            verifyNotEmpty(testCase, traceparentrow);

            % verify the traceparent field contains both the trace and span IDs
            verifySubstring(testCase, headers(traceparentrow,2), string(results.resourceSpans.scopeSpans.spans.traceId));
            verifySubstring(testCase, headers(traceparentrow,2), string(results.resourceSpans.scopeSpans.spans.spanId));
        end

        function testExtractContextComposite(testCase)
            % testExtractContextComposite: extractContext convenience function for composite extract

            % set global propagator
            propagator = opentelemetry.context.propagation.CompositePropagator(...
                opentelemetry.trace.propagation.TraceContextPropagator, ...
                opentelemetry.baggage.propagation.BaggagePropagator);
            opentelemetry.context.propagation.Propagator.setTextMapPropagator(propagator);

            % set up carrier and extract
            carrier = opentelemetry.context.propagation.TextMapCarrier([testCase.Headers; ...
                testCase.BaggageHeaders]);
            context = opentelemetry.context.propagation.extractContext(carrier);

            % extract baggage and verify
            bag = opentelemetry.baggage.Context.extractBaggage(context);
            bag = bag.Entries;

            baggagekeys = testCase.BaggageKeys;
            nkeys = length(baggagekeys);
            for i = 1:nkeys
                verifyTrue(testCase, isKey(bag, baggagekeys(i)));
                verifyEqual(testCase, bag(baggagekeys(i)), testCase.BaggageValues(i));
            end

            % extract span and verify
            span = opentelemetry.trace.Context.extractSpan(context);
            spancontext = getSpanContext(span);

            % verify extracted trace and span IDs and trace state
            verifyEqual(testCase, spancontext.TraceId, testCase.TraceId);
            verifyEqual(testCase, spancontext.SpanId, testCase.SpanId);
            verifyEqual(testCase, spancontext.TraceState, testCase.TraceState);
        end

        function testInjectContextComposite(testCase)
            % testInjectContextComposite: injectContext convenience function for composite injection

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
            bag = opentelemetry.baggage.Baggage(dictionary(testCase.BaggageKeys, ...
                testCase.BaggageValues));
            context = opentelemetry.context.getCurrentContext();
            newcontext = opentelemetry.baggage.Context.insertBaggage(context, bag);
            token = setCurrentContext(newcontext); %#ok<NASGU>

            % inject
            carrier = opentelemetry.context.propagation.injectContext();
            headers = carrier.Headers;
            endSpan(sp);

            % verify the baggage header
            baggagerow = find(headers(:,1) == "baggage");
            verifyNotEmpty(testCase, baggagerow);
            verifyEqual(testCase, headers(baggagerow,:), testCase.BaggageHeaders);

            % verify the injected traceparent contains the trace and span IDs
            traceparentrow = find(headers(:,1) == "traceparent");
            verifyNotEmpty(testCase, traceparentrow);
            spancontext = getSpanContext(sp);
            verifySubstring(testCase, headers(traceparentrow,2), spancontext.TraceId);
            verifySubstring(testCase, headers(traceparentrow,2), spancontext.SpanId);
        end
    end
end
