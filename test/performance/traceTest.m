classdef traceTest < matlab.perftest.TestCase
% performance tests for tracing

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
    end
    
    methods (TestClassSetup)
        function setupOnce(testCase)
            testdir = fileparts(mfilename("fullpath"));
            addpath(fullfile(testdir, ".."));  % add directory where common setup and teardown code lives
            commonSetupOnce(testCase);
        end
    end

    methods (TestMethodSetup)
        function setup(testCase)
            commonSetup(testCase);

            % create a global tracer provider
            import opentelemetry.sdk.trace.*
            tp = TracerProvider(BatchSpanProcessor());
            setTracerProvider(tp);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            commonTeardown(testCase);
        end
    end

    methods (Test)
        function testSpan(testCase)
            % start and end a span
            tr = opentelemetry.trace.getTracer("Tracer");

            testCase.startMeasuring();
            sp = startSpan(tr, "Span");
            endSpan(sp);
            testCase.stopMeasuring();
        end

        function testCurrentSpan(testCase)
            % start a span, put it in current context, end the span
            tr = opentelemetry.trace.getTracer("Tracer");

            testCase.startMeasuring();
            sp = startSpan(tr, "Span");
            scope = makeCurrent(sp); %#ok<NASGU>
            endSpan(sp);
            testCase.stopMeasuring();
        end

        function testNestedSpansImplicitContext(testCase)
            % nested spans, using current span as parent
            tr = opentelemetry.trace.getTracer("Tracer");

            testCase.startMeasuring();
            osp = startSpan(tr, "outer");
            oscope = makeCurrent(osp); %#ok<NASGU>

            isp = startSpan(tr, "inner");
            iscope = makeCurrent(isp); %#ok<NASGU>

            imsp = startSpan(tr, "innermost");
            
            endSpan(imsp);
            endSpan(isp);
            endSpan(osp);
            testCase.stopMeasuring();
        end

        function testNestedSpansExplicitContext(testCase)
            % nested spans, explicitly setting parents
            tr = opentelemetry.trace.getTracer("Tracer");

            testCase.startMeasuring();
            osp = startSpan(tr, "outer");
            context = insertSpan(osp);

            isp = startSpan(tr, "inner", Context=context);
            context = insertSpan(isp, context);

            imsp = startSpan(tr, "innermost", Context=context);
            
            endSpan(imsp);
            endSpan(isp);
            endSpan(osp);
            testCase.stopMeasuring();
        end

        function testAttributes(testCase)
            % span with 3 attributes
            tr = opentelemetry.trace.getTracer("Tracer");
            m = magic(4);

            testCase.startMeasuring();
            sp = startSpan(tr, "Span");
            setAttributes(sp, "attribute 1", "value 1", "attribute 2", 10, ...
                "attribute 3", m);
            endSpan(sp);
            testCase.stopMeasuring()
        end

        function testEvents(testCase)
            % span with 3 events
            tr = opentelemetry.trace.getTracer("Tracer");

            testCase.startMeasuring();
            sp = startSpan(tr, "Span");
            addEvent(sp, "event 1")
            addEvent(sp, "event 2");
            addEvent(sp, "event 3");
            endSpan(sp);
            testCase.stopMeasuring()
        end

        function testLinks(testCase)
            % span with 2 links
            tr = opentelemetry.trace.getTracer("Tracer");
            sp1 = startSpan(tr, "Span 1");
            sp1ctxt = getSpanContext(sp1);
            sp2 = startSpan(tr, "Span 2");
            sp2ctxt = getSpanContext(sp2);

            testCase.startMeasuring();
            link1 = opentelemetry.trace.Link(sp1ctxt);
            link2 = opentelemetry.trace.Link(sp2ctxt);
            sp3 = startSpan(tr, "Span 3", Links=[link1 link2]);
            endSpan(sp3);
            testCase.stopMeasuring()
        end

        function testGetTracer(testCase)
            % get a tracer from the global tracer provider instance
            testCase.startMeasuring();
            tr = opentelemetry.trace.getTracer("Tracer"); %#ok<NASGU>
            testCase.stopMeasuring();
        end

        function testCreateDefaultTracerProvider(testCase)
            % create default TracerProvider in the sdk
            testCase.startMeasuring();
            tp = opentelemetry.sdk.trace.TracerProvider(); %#ok<NASGU>
            testCase.stopMeasuring();
        end

        function testSpanContext(testCase)
            % retrieve trace ID and span ID in the span context
            tr = opentelemetry.trace.getTracer("Tracer");
            sp = startSpan(tr, "Span");

            testCase.startMeasuring();
            spctxt = getSpanContext(sp);
            traceid = spctxt.TraceId; %#ok<NASGU>
            spanid = spctxt.SpanId; %#ok<NASGU>
            testCase.stopMeasuring();
        end

    end
end
