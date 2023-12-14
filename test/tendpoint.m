classdef tendpoint < matlab.unittest.TestCase
    % tests for setting endpoint in the exporter

    % Copyright 2023 The MathWorks, Inc.

    properties
        OtelConfigFile
        JsonFile
        PidFile
        OtelcolName
        Otelcol
        ListPid
        ReadPidList
        ExtractPid
        Sigint
        Sigterm
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            commonSetupOnce(testCase);
        end
    end

    methods (TestMethodSetup)
        function setup(testCase)
            commonSetup(testCase, "nondefault_endpoint.yml");
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            commonTeardown(testCase);
        end
    end

    methods (Test)
        function testNondefaultEndpoint(testCase)
            % testNondefaultEndpoint: using an alternative endpoint

            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpHttpSpanExporter", "class")), ...
                "Otlp HTTP exporter must be installed.");

            tracername = "foo";
            spanname = "bar";

            exp = opentelemetry.exporters.otlp.OtlpHttpSpanExporter(...
                "Endpoint", "http://localhost:9921/v1/traces");
            processor = opentelemetry.sdk.trace.SimpleSpanProcessor(exp);
            tp = opentelemetry.sdk.trace.TracerProvider(processor);
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, spanname);
            pause(1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check span and tracer names
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.scope.name), tracername);
        end

        function testNondefaultGrpcEndpoint(testCase)
            % testNondefaultGrpcEndpoint: using an alternative endpoint

            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpGrpcSpanExporter", "class")), ...
                "Otlp gRPC exporter must be installed.");

            tracername = "foo";
            spanname = "bar";

            exp = opentelemetry.exporters.otlp.OtlpGrpcSpanExporter(...
                "Endpoint", "http://localhost:9922");
            processor = opentelemetry.sdk.trace.SimpleSpanProcessor(exp);
            tp = opentelemetry.sdk.trace.TracerProvider(processor);
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, spanname);
            pause(1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check span and tracer names
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.scope.name), tracername);
        end

        function NondefaultMetricsEndpoint(testCase)
            % testNondefaultMetricsEndpoint: using an alternative endpoint
            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpHttpMetricExporter", "class")), ...
                "Otlp HTTP exporter must be installed.");

            exp = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "Endpoint", "http://localhost:9921/v1/metrics");
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(...
                exp, "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter("foo");
            ct = mt.createCounter("bar");

            val = 4;
            ct.add(val);
            pause(2.5);

            % fetch result
            clear p;
            results = readJsonResults(testCase);

            % verify counter value
            verifyEqual(testCase, results{end}.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, val);
        end

        function NondefaultGrpcMetricsEndpoint(testCase)
            % testNondefaultGrpcMetricsEndpoint: using an alternative endpoint
            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpGrpcMetricExporter", "class")), ...
                "Otlp gRPC exporter must be installed.");

            exp = opentelemetry.exporters.otlp.OtlpGrpcMetricExporter(...
                "Endpoint", "http://localhost:9922");
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(...
                exp, "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter("foo");
            ct = mt.createCounter("bar");

            val = 8;
            ct.add(val);
            pause(2.5);

            % fetch result
            clear p;
            results = readJsonResults(testCase);

            % verify counter value
            verifyEqual(testCase, results{end}.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, val);
        end

    end
end