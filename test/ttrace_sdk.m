classdef ttrace_sdk < matlab.unittest.TestCase
    % tests for tracing SDK (span processors, exporters, samplers, resource)

    % Copyright 2023-2024 The MathWorks, Inc.

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
        function testAlwaysOffSampler(testCase)
            % testAlwaysOffSampler: should not produce any spans
            tp = opentelemetry.sdk.trace.TracerProvider( ...
                opentelemetry.sdk.trace.SimpleSpanProcessor, ...
                "Sampler", opentelemetry.sdk.trace.AlwaysOffSampler);
            tr = getTracer(tp, "mytracer");
            sp = startSpan(tr, "myspan");
            pause(1);
            endSpan(sp);

            % verify no spans are generated
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);
        end

        function testAlwaysOnSampler(testCase)
            % testAlwaysOnSampler: should produce all spans
            tracername = "foo";
            spanname = "bar";

            tp = opentelemetry.sdk.trace.TracerProvider( ...
                opentelemetry.sdk.trace.SimpleSpanProcessor, ...
                "Sampler", opentelemetry.sdk.trace.AlwaysOnSampler);
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

        function testTraceIdRatioBasedSampler(testCase)
            % testTraceIdRatioBasedSampler: filter spans based on a ratio
            s = opentelemetry.sdk.trace.TraceIdRatioBasedSampler(0); % equivalent to always off

            tracername = "mytracer";
            offspan = "offspan";
            tp = opentelemetry.sdk.trace.TracerProvider( ...
                opentelemetry.sdk.trace.SimpleSpanProcessor, "Sampler", s); 
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, offspan);
            pause(1);
            endSpan(sp);

            s.Ratio = 1;  % equivalent to always on
            onspan = "onspan";
            tp = opentelemetry.sdk.trace.TracerProvider( ...
                opentelemetry.sdk.trace.SimpleSpanProcessor, "Sampler", s); 
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, onspan);
            pause(1);
            endSpan(sp);

            s.Ratio = 0.5;  % filter half of the spans
            sampledspan = "sampledspan";
            numspans = 10;
            tp = opentelemetry.sdk.trace.TracerProvider( ...
                opentelemetry.sdk.trace.SimpleSpanProcessor, "Sampler", s); 
            tr = getTracer(tp, tracername);
            for i = 1:numspans
                sp = startSpan(tr, sampledspan + i);
                pause(1);
                endSpan(sp);
            end

            % perform test comparisons
            results = readJsonResults(testCase);
            n = length(results);
            % total spans should be 1 span when ratio == 1, plus a number of
            % spans between 0 and numspans when ratio == 0.5
            % Verifying 1 < total_spans < numspans+1. If this fails, there
            % is still a chance nothing went wrong, because number of spans
            % are non-deterministic when ratio == 0.5. When ratio == 0.5,
            % it is still possible to get 0 or numspans spans. But that
            % probability is small, so we fail the test to flag something
            % may have gone wrong.
            verifyGreaterThan(testCase, n, 1);
            verifyLessThan(testCase, n, 1 + numspans);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), onspan);
            for i = 2:n
                verifySubstring(testCase, string(results{i}.resourceSpans.scopeSpans.spans.name), ...
                    sampledspan);
            end
        end

        function testOtlpFileExporter(testCase)
            % testOtlpFileExporter: use a file exporter to write to files

            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpFileSpanExporter", "class")), ...
                "Otlp file exporter must be installed.");

            % create temporary folder to write the output files
            folderfixture = testCase.applyFixture(...
                matlab.unittest.fixtures.TemporaryFolderFixture);
   
            % create file exporter
            output = fullfile(folderfixture.Folder,"output%n.json");
            alias = fullfile(folderfixture.Folder,"output_latest.json");
            exp = opentelemetry.exporters.otlp.OtlpFileSpanExporter(...
                FileName=output, AliasName=alias);

            tp = opentelemetry.sdk.trace.TracerProvider(...
                opentelemetry.sdk.trace.SimpleSpanProcessor(exp));      

            tracername = "foo";
            spanname = "bar";
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, spanname); %#ok<NASGU>
            pause(1);
            clear("sp", "tr", "tp");

            % perform test comparisons
            results = jsondecode(fileread(alias));

            % check span and tracer names
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.scope.name), tracername);
        end

        function testCustomResource(testCase)
            % testCustomResource: check custom resources are included in
            % emitted spans
            customkeys = ["foo" "bar"];
            customvalues = [1 5];
            tp = opentelemetry.sdk.trace.TracerProvider(opentelemetry.sdk.trace.SimpleSpanProcessor, ...
                "Resource", dictionary(customkeys, customvalues)); 
            tr = getTracer(tp, "mytracer");
            sp = startSpan(tr, "myspan");
            pause(1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            resourcekeys = string({results.resourceSpans.resource.attributes.key});
            for i = length(customkeys)
                idx = find(resourcekeys == customkeys(i));
                verifyNotEmpty(testCase, idx);
                verifyEqual(testCase, results.resourceSpans.resource.attributes(idx).value.doubleValue, customvalues(i));
            end
        end

        function testShutdown(testCase)
            % testShutdown: shutdown method should stop exporting
            % of spans
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");

            % start and end a span 
            spanname = "bar";
            sp = startSpan(tr, spanname);
            endSpan(sp);

            % shutdown the tracer provider
            verifyTrue(testCase, shutdown(tp));

            % suppress internal error logs about span export failure
            nologs = SuppressInternalLogs; %#ok<NASGU>

            % start and end another span
            sp1 = startSpan(tr, "quux");
            endSpan(sp1);

            % verify only the first span was generated
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), spanname);
        end

        function testCleanupSdk(testCase)
            % testCleanupSdk: shutdown an SDK tracer provider through the Cleanup class
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");

            % start and end a span 
            spanname = "bar";
            sp = startSpan(tr, spanname);
            endSpan(sp);

            % shutdown the SDK tracer provider through the Cleanup class
            verifyTrue(testCase, opentelemetry.sdk.common.Cleanup.shutdown(tp));

            % suppress internal error logs about span export failure
            nologs = SuppressInternalLogs; %#ok<NASGU>

            % start and end another span
            sp1 = startSpan(tr, "quux");
            endSpan(sp1);

            % verify only the first span was generated
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), spanname);
        end

        function testCleanupApi(testCase)
            % testCleanupApi: shutdown an API tracer provider through the Cleanup class  
            tp = opentelemetry.sdk.trace.TracerProvider();
            setTracerProvider(tp);
            clear("tp");
            tp_api = opentelemetry.trace.Provider.getTracerProvider();
            tr = getTracer(tp_api, "foo");

            % start and end a span 
            spanname = "bar";
            sp = startSpan(tr, spanname);
            endSpan(sp);

            % shutdown the API tracer provider through the Cleanup class
            verifyTrue(testCase, opentelemetry.sdk.common.Cleanup.shutdown(tp_api));

            % suppress internal error logs about span export failure
            nologs = SuppressInternalLogs; %#ok<NASGU>
            
            % start and end another span
            sp1 = startSpan(tr, "quux");
            endSpan(sp1);

            % verify only the first span was generated
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), spanname);
        end
    end
end