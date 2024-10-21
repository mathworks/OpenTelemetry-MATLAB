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
            % add the example folder to the path
            example1folder = fullfile(fileparts(mfilename('fullpath')), "autotrace_examples", "example1");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(example1folder));
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
        function testBasic(testCase)
            % testBasic: instrument a simple example

            % configure the global tracer provider
            tp = opentelemetry.sdk.trace.TracerProvider();
            setTracerProvider(tp);
            clear("tp");

            % set up AutoTrace
            at = opentelemetry.autoinstrument.AutoTrace(@example1);

            % run the example
            [~] = beginTrace(at, 100);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);

            % check logger name, log body and severity, trace and span IDs
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.scope.name), "AutoTrace");
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), "generate_data");
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.name), "best_fit_line");
            verifyEqual(testCase, string(results{3}.resourceSpans.scopeSpans.spans.name), "example1");
        end
    end
end