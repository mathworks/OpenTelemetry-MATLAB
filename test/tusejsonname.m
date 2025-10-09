classdef tusejsonname < matlab.unittest.TestCase
    % tests for setting UseJsonName in the exporter

    % Copyright 2025 The MathWorks, Inc.

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
            % add the utils folder to the path
            utilsfolder = fullfile(fileparts(mfilename('fullpath')), "utils");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(utilsfolder));
            commonSetupOnce(testCase);
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
        function testNondefaultUseJsonName(testCase)
            % testNondefaultUseJsonName: using an alternative UseJsonName

            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpHttpSpanExporter", "class")), ...
                "Otlp HTTP exporter must be installed.");

            tracername = "foo";
            spanname = "bar";

            exp = opentelemetry.exporters.otlp.OtlpHttpSpanExporter(...
                "UseJsonName", true);
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

        function testNondefaultGrpcUseJsonName(testCase)
            % testNondefaultGrpcUseJsonName: using an alternative UseJsonName

            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpGrpcSpanExporter", "class")), ...
                "Otlp gRPC exporter must be installed.");

            tracername = "foo";
            spanname = "bar";

            exp = opentelemetry.exporters.otlp.OtlpGrpcSpanExporter(...
                "UseJsonName", true);
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

        function NondefaultMetricsUseJsonName(testCase)
            % testNondefaultMetricsUseJsonName: using an alternative UseJsonName
            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpHttpMetricExporter", "class")), ...
                "Otlp HTTP exporter must be installed.");

            exp = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "UseJsonName", true);
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

        function NondefaultGrpcMetricsUseJsonName(testCase)
            % testNondefaultGrpcMetricsUseJsonName: using an alternative UseJsonName
            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpGrpcMetricExporter", "class")), ...
                "Otlp gRPC exporter must be installed.");

            exp = opentelemetry.exporters.otlp.OtlpGrpcMetricExporter(...
                "UseJsonName", true);
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