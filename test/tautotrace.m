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
        
            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example);

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check tracer and span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.scope.name), "AutoTrace");   % default name
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "best_fit_line");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "linearfit_example");

            % check they belong to the same trace
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.traceId, results{2}.resourceSpans.scopeSpans.spans.traceId);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.traceId, results{3}.resourceSpans.scopeSpans.spans.traceId);

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
        end

        function testIncludeExcludeFiles(testCase)
            % testIncludeExcludeFiles: AdditionalFiles and ExcludeFiles options

            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example, ...
                "AdditionalFiles", "polyfit", "ExcludeFiles", "generate_data");

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "polyfit");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "best_fit_line");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "linearfit_example");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
        end

        function testDisableFileDetection(testCase)
            % testDisableFileDetection: AutoDetectFiles set to false

            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example, ...
                "AutoDetectFiles", false);

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);

            % should only be 1 span
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "linearfit_example");
        end

        function testIncludeFolder(testCase)
            % testIncludeFolder: specify a folder in AdditionalFiles
           
            % Add example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "subfolder_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder, ...
                "IncludingSubfolders",true));

            % set up AutoTrace, turn off automatic detection and specify 
            % dependencies using their folder name
            at = opentelemetry.autoinstrument.AutoTrace(@subfolder_example, ...
                "AutoDetectFiles", false, "AdditionalFiles", fullfile(examplefolder, "helpers"));

            % run the example
            [~] = beginTrace(at);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "subfolder_helper1");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "subfolder_helper2");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "subfolder_example");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
        end

        function testExcludeFolder(testCase)
            % testExcludeFolder: specify a folder in ExcludeFiles
            
            % Add example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "subfolder_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder, ...
                "IncludingSubfolders",true));

            % set up AutoTrace and exclude helper folder          
            at = opentelemetry.autoinstrument.AutoTrace(@subfolder_example, ...
                "ExcludeFiles", fullfile(examplefolder, "helpers"));

            % run the example
            [~] = beginTrace(at);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "subfolder_example");
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

            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example, ...
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
        
            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example);

            % run the example with an invalid input, check for error
            verifyError(testCase, @()beginTrace(at, "invalid"), "autotrace_examples:linearfit_example:generate_data:InvalidN");

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 2);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "linearfit_example");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);

            % check error status
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.status.code, 2);  % error 
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.status.message, ...
                'Input must be a numeric scalar');  
            verifyEmpty(testCase, fieldnames(results{2}.resourceSpans.scopeSpans.spans.status));  % ok, no error
        end

        function testHandleError(testCase)
            % testHandleError: directly call handleError method rather than using
            % beginTrace method. This test should use linearfit_example_trycatch, which
            % wraps a try-catch in the input function and calls handleError
            % in the catch block.

            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % set up AutoTrace, using linearfit_example_trycatch
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example_trycatch);

            % call example directly instead of calling beginTrace, and pass
            % in an invalid input
            verifyError(testCase, @()linearfit_example_trycatch(at, "invalid"), ...
                "autotrace_examples:linearfit_example:generate_data:InvalidN");

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 2);

            % check span names
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "linearfit_example_trycatch");

            % check parent children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);

            % check error status
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.status.code, 2);  % error
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.status.message, ...
                'Input must be a numeric scalar');  
            verifyEmpty(testCase, fieldnames(results{2}.resourceSpans.scopeSpans.spans.status));  % ok, no error
        end

        function testMultipleInstances(testCase)
            % testMultipleInstances: multiple overlapped instances should
            % return an error

            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example); %#ok<NASGU>

            % set up another identical instance, check for error
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@linearfit_example), "opentelemetry:autoinstrument:AutoTrace:OverlappedInstances");
        end

        function testClearInstance(testCase)
            % testClearInstance: clear an instance and recreate a new instance

            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % create and instance and then clear
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example); %#ok<NASGU>
            clear("at")

            % create a new instance should not result in any error
            at = opentelemetry.autoinstrument.AutoTrace(@linearfit_example); %#ok<NASGU>
        end

        function testInvalidInputFunction(testCase)
            % testInvalidInputFunction: negative test for invalid input

            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "linearfit_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            
            % anonymous function
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@()linearfit_example), "opentelemetry:autoinstrument:AutoTrace:AnonymousFunction");

            % builtin function
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@uplus), "opentelemetry:autoinstrument:AutoTrace:BuiltinFunction");

            % nonexistent function
            verifyError(testCase, @()opentelemetry.autoinstrument.AutoTrace(@bogus), "opentelemetry:autoinstrument:AutoTrace:InvalidMFile");
        end

        function testAutoManualInstrument(testCase)
            % testAutoManualInstrument: using both auto and manual
            % instrumentation
            
            % add the example folders to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "manual_instrumented_example");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@manual_instrumented_example);

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 6);

            % check tracer and span names
            tracername = "ManualInstrument";
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.scope.name), tracername); 
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.scope.name), tracername); 
            verifyEqual(testCase, string(results{4}.resourceSpans.scopeSpans.scope.name), tracername); 
            
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "compute_y");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "polyfit");
            verifyEqual(testCase, string(results{4}.resourceSpans.scopeSpans.spans.name), "polyval");
            verifyEqual(testCase, string(results{5}.resourceSpans.scopeSpans.spans.name), "best_fit_line");
            verifyEqual(testCase, string(results{6}.resourceSpans.scopeSpans.spans.name), "manual_instrumented_example");

            % check auto and manual spans belong to the same trace
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.traceId, results{6}.resourceSpans.scopeSpans.spans.traceId);
            verifyEqual(testCase, results{3}.resourceSpans.scopeSpans.spans.traceId, results{6}.resourceSpans.scopeSpans.spans.traceId);
            verifyEqual(testCase, results{4}.resourceSpans.scopeSpans.spans.traceId, results{6}.resourceSpans.scopeSpans.spans.traceId);

            % check parent children relationship of manual spans
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{3}.resourceSpans.scopeSpans.spans.parentSpanId, results{5}.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, results{4}.resourceSpans.scopeSpans.spans.parentSpanId, results{5}.resourceSpans.scopeSpans.spans.spanId);
        end
    end
end