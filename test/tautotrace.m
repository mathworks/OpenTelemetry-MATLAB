classdef tautotrace < matlab.unittest.TestCase
    % tests for AutoTrace

    % Copyright 2024 The MathWorks, Inc.

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
            % add the example folders to the path
            example1folder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "example1");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(example1folder));
            example2folder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "example2");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(example2folder));
            example2helpersfolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "example2", "helpers");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(example2helpersfolder));
            commonSetupOnce(testCase);

            % configure the global tracer provider
            tp = opentelemetry.sdk.trace.TracerProvider();
            setTracerProvider(tp);
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
        function testBasic(testCase)
            % testBasic: instrument a simple example
        
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@example1);

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check tracer and span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.scope.name), "AutoTrace");   % default name
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "best_fit_line");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "example1");

            % check they belong to the same trace
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.traceId, results{2}.resourceSpans.scopeSpans.spans.traceId);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.traceId, results{3}.resourceSpans.scopeSpans.spans.traceId);

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
        end

        function testIncludeExcludeFiles(testCase)
            % testIncludeExcludeFiles: AdditionalFiles and ExcludeFiles options

            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@example1, ...
                "AdditionalFiles", "polyfit", "ExcludeFiles", "generate_data");

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "polyfit");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "best_fit_line");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "example1");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
        end

        function testDisableFileDetection(testCase)
            % testDisableFileDetection: AutoDetectFiles set to false

            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@example1, ...
                "AutoDetectFiles", false);

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);

            % should only be 1 span
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "example1");
        end

        function testIncludeFolder(testCase)
            % testIncludeFolder: specify a folder in AdditionalFiles
           
            % set up AutoTrace
            example2helpers = fullfile(fileparts(mfilename('fullpath')), ...
                "autotrace_examples", "example2", "helpers");            
            % turn off automatic detection and specify dependencies using
            % their folder name
            at = opentelemetry.autoinstrument.AutoTrace(@example2, ...
                "AutoDetectFiles", false, "AdditionalFiles", example2helpers);

            % run the example
            [~] = beginTrace(at);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "ex2helper1");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "ex2helper2");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "example2");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
        end

        function testExcludeFolder(testCase)
            % testExcludeFolder: specify a folder in ExcludeFiles
            
            % set up AutoTrace
            example2helpers = fullfile(fileparts(mfilename('fullpath')), ...
                "autotrace_examples", "example2", "helpers");            
            at = opentelemetry.autoinstrument.AutoTrace(@example2, ...
                "ExcludeFiles", example2helpers);

            % run the example
            [~] = beginTrace(at);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "example2");
        end

        function testNonFileOptions(testCase)
            % testNonFileOptions: other options not related to files,
            % "TracerName", "TracerVersion", "TracerSchema", "Attributes",
            % "SpanKind"
        
            tracername = "foo";
            tracerversion = "1.1";
            tracerschema = "https://opentelemetry.io/schemas/1.28.0";
            spankind = "consumer";
            attrnames = ["foo" "bar"];
            attrvalues = [1 2];
            attrs = dictionary(attrnames, attrvalues);
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@example1, ...
                "TracerName", tracername, "TracerVersion", tracerversion, ...
                "TracerSchema", tracerschema, "SpanKind", spankind, "Attributes", attrs);

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check specified options in each span
            for i = 1:numel(results)
                verifyEqual(testCase, string(results{i}.resourceSpans.scopeSpans.scope.name), tracername);
                verifyEqual(testCase, string(results{i}.resourceSpans.scopeSpans.scope.version), tracerversion);
                verifyEqual(testCase, string(results{i}.resourceSpans.scopeSpans.schemaUrl), tracerschema);
                verifyEqual(testCase, results{i}.resourceSpans.scopeSpans.spans.kind, 5);  % SpanKind consumer

                % attributes
                attrkeys = string({results{i}.resourceSpans.scopeSpans.spans.attributes.key});

                for ii = 1:numel(attrnames)
                    attrnameii = attrnames(ii);
                    idxii = find(attrkeys == attrnameii);
                    verifyNotEmpty(testCase, idxii);
                    verifyEqual(testCase, results{i}.resourceSpans.scopeSpans.spans.attributes(idxii).value.doubleValue, ...
                        attrvalues(ii));
                end
            end
        end

        function testError(testCase)
            % testError: handling error situation
        
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@example1);

            % run the example with an invalid input, check for error
            verifyError(testCase, @()beginTrace(at, "invalid"), "autotrace_examples:example1:generate_data:InvalidN");

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 2);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "example1");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);

            % check error status
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.status.code, 2);  % error 
            verifyEmpty(testCase, fieldnames(results{2}.resourceSpans.scopeSpans.spans.status));  % ok, no error
        end

        function testHandleError(testCase)
            % testHandleError: directly call handleError method rather than using
            % beginTrace method. This test should use example1_trycatch, which
            % wraps a try-catch in the input function and calls handleError
            % in the catch block.

            % set up AutoTrace, using example1_trycatch
            at = opentelemetry.autoinstrument.AutoTrace(@example1_trycatch);

            % call example directly instead of calling beginTrace, and pass
            % in an invalid input
            verifyError(testCase, @()example1_trycatch(at, "invalid"), "autotrace_examples:example1:generate_data:InvalidN");

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 2);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "example1_trycatch");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);

            % check error status
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.status.code, 2);  % error
            verifyEmpty(testCase, fieldnames(results{2}.resourceSpans.scopeSpans.spans.status));  % ok, no error
        end

        function testMultipleInstances(testCase)
            % testMultipleInstances: multiple overlapped instances should
            % return an error

            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@example1); %#ok<NASGU>

            % set up another identical instance, check for error
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@example1), "opentelemetry:autoinstrument:AutoTrace:OverlappedInstances");
        end

        function testClearInstance(~)
            % testClearInstance: clear an instance and recreate a new instance

            % create and instance and then clear
            at = opentelemetry.autoinstrument.AutoTrace(@example1); %#ok<NASGU>
            clear("at")

            % create a new instance should not result in any error
            at = opentelemetry.autoinstrument.AutoTrace(@example1); %#ok<NASGU>
        end

        function testInvalidInputFunction(testCase)
            % testInvalidInputFunction: negative test for invalid input

            % anonymous function
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@()example1), "opentelemetry:autoinstrument:AutoTrace:AnonymousFunction");

            % builtin function
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@uplus), "opentelemetry:autoinstrument:AutoTrace:BuiltinFunction");

            % nonexistent function
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@bogus), "opentelemetry:autoinstrument:AutoTrace:InvalidMFile");
        end
    end
end