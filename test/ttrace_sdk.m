classdef ttrace_sdk < matlab.unittest.TestCase
    % tests for tracing SDK (span processors, exporters, samplers, resource)

    % Copyright 2023-2025 The MathWorks, Inc.

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
        ForceFlushTimeout
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            % add the utils and fixtures folders to the path
            folders = fullfile(fileparts(mfilename('fullpath')), ["utils" "fixtures"]);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folders));
            commonSetupOnce(testCase);
            testCase.ForceFlushTimeout = seconds(2);
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
        function testBatchSpanProcessor(testCase)
            % testBatchSpanProcessor: setting properties of
            % BatchSpanProcessor
            tracername = "foo";
            spanname = "bar";

            queuesize = 500;
            delay = seconds(2);
            batchsize = 50;
            b = opentelemetry.sdk.trace.BatchSpanProcessor(...
                MaximumQueueSize=queuesize, ...
                ScheduledDelay=delay, ...
                MaximumExportBatchSize=batchsize);
            tp = opentelemetry.sdk.trace.TracerProvider(b);
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, spanname);
            pause(1);
            endSpan(sp);

            % verify batch properties set correctly
            verifyEqual(testCase, b.MaximumQueueSize, queuesize);
            verifyEqual(testCase, b.ScheduledDelay, delay);
            verifyEqual(testCase, b.MaximumExportBatchSize, batchsize)
            verifyEqual(testCase, class(b.SpanExporter), ...
                class(opentelemetry.exporters.otlp.defaultSpanExporter));

            % perform test comparisons
            forceFlush(tp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            results = results{1};

            % check span and tracer names
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.scope.name), tracername);
        end

        function testAlwaysOffSampler(testCase)
            % testAlwaysOffSampler: should not produce any spans
            tp = opentelemetry.sdk.trace.TracerProvider( ...
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

        function testParentBasedSampler(testCase)
            % testParentBasedSampler: should produce all spans
            tracername = "tracer - AlwaysOnSampler";
            spanname = "span - AlwaysOnSampler";

            tp = opentelemetry.sdk.trace.TracerProvider( ...
                "Sampler", opentelemetry.sdk.trace.ParentBasedSampler(opentelemetry.sdk.trace.AlwaysOnSampler));
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, spanname);
            pause(1);
            endSpan(sp);

            tracername1 = "tracer - AlwaysOffSampler";
            spanname1 = "span - AlwaysOffSampler";
            tp = opentelemetry.sdk.trace.TracerProvider( ...
                "Sampler", opentelemetry.sdk.trace.ParentBasedSampler(opentelemetry.sdk.trace.AlwaysOffSampler));
            tr = getTracer(tp, tracername1);
            sp = startSpan(tr, spanname1);
            pause(1);
            endSpan(sp);

            tracername2 = "tracer - TraceIdRatioBasedSampler";
            spanname2 = "span - TraceIdRatioBasedSampler";
            tp = opentelemetry.sdk.trace.TracerProvider( ...
                "Sampler", opentelemetry.sdk.trace.ParentBasedSampler(opentelemetry.sdk.trace.TraceIdRatioBasedSampler(1)));
            tr = getTracer(tp, tracername2);
            sp = startSpan(tr, spanname2);
            pause(1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);

            % check span and tracer names of an AlwaysOnSampler
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.scope.name), tracername);

            % AlwaysOffSampler should return no results

            % check span and tracer names of an TraceIdRatioBasedSampler
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), spanname2);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.scope.name), tracername2);

            % check ParentBasedSampler doesn't accept other inputs
            verifyError(testCase, @()  opentelemetry.sdk.trace.TracerProvider( ...
                "Sampler", opentelemetry.sdk.trace.ParentBasedSampler(opentelemetry.sdk.trace.ParentBasedSampler("not a sampler"))), "MATLAB:validators:mustBeA");
        end

        function testTraceIdRatioBasedSampler(testCase)
            % testTraceIdRatioBasedSampler: filter spans based on a ratio
            s = opentelemetry.sdk.trace.TraceIdRatioBasedSampler(0); % equivalent to always off

            tracername = "mytracer";
            offspan = "offspan";
            tp = opentelemetry.sdk.trace.TracerProvider("Sampler", s); 
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, offspan);
            pause(1);
            endSpan(sp);

            s.Ratio = 1;  % equivalent to always on
            onspan = "onspan";
            tp = opentelemetry.sdk.trace.TracerProvider("Sampler", s); 
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, onspan);
            pause(1);
            endSpan(sp);

            s.Ratio = 0.5;  % filter half of the spans
            sampledspan = "sampledspan";
            numspans = 10;
            tp = opentelemetry.sdk.trace.TracerProvider("Sampler", s); 
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
            resultstxt = readlines(alias);
            results = jsondecode(resultstxt(1));

            % check span and tracer names
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.scope.name), tracername);
        end

        function testCustomResource(testCase)
            % testCustomResource: check custom resources are included in
            % emitted spans
            customkeys = ["foo" "bar"];
            customvalues = [1 5];
            tp = opentelemetry.sdk.trace.TracerProvider("Resource", dictionary(customkeys, customvalues)); 
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
            testCase.applyFixture(TracerProviderFixture(tp));  % set TracerProvider global instance
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