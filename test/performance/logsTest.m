classdef logsTest < matlab.perftest.TestCase
% performance tests for logs

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
            % add directory where common setup and teardown code lives
            utilsfolder = fullfile(fileparts(mfilename('fullpath')), "..", "utils");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(utilsfolder));

            commonSetupOnce(testCase);

            % create a global logger provider
            import opentelemetry.sdk.logs.*
            lp = LoggerProvider(BatchLogRecordProcessor());
            setLoggerProvider(lp);
        end
    end

    methods (TestMethodSetup)
        function setup(testCase)
            commonSetup(testCase);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            % Flush any log records that have not yet been exported
            lp = opentelemetry.logs.Provider.getLoggerProvider();
            opentelemetry.sdk.common.Cleanup.forceFlush(lp);

            commonTeardown(testCase);
        end
    end

    methods (Test)
        function testEmitLogRecord(testCase)
            % create and emit a log record
            lg = opentelemetry.logs.getLogger("foo");

            testCase.startMeasuring();
            % run through a loop since the time for 1 iteration is too short
            for i = 1:10
                emitLogRecord(lg, "info", "bar");
            end
            testCase.stopMeasuring();
        end

        function testAttributes(testCase)
            % create and emit a log record with attributes
            lg = opentelemetry.logs.getLogger("foo");
            attrs = dictionary(["attribute1", "attribute2"], ["value1", "value2"]);

            testCase.startMeasuring();
            emitLogRecord(lg, "info", "bar", Attributes=attrs);
            testCase.stopMeasuring();
        end

        function testFrontEndAPI(testCase)
            % Call frontend API functions to emit a log record (trace,
            % debug, info, warn, error, fatal)
            lg = opentelemetry.logs.getLogger("foo");

            testCase.startMeasuring();
            trace(lg, "bar");
            debug(lg, "bar");
            info(lg, "bar");
            warn(lg, "bar");
            error(lg, "bar");
            fatal(lg, "bar");
            testCase.stopMeasuring();
        end

        function testGetLogger(testCase)
            % get a logger from the global logger provider instance
            testCase.startMeasuring();
            lg = opentelemetry.logs.getLogger("foo"); %#ok<*NASGU>
            testCase.stopMeasuring();
        end

        function testCreateDefaultLoggerProvider(testCase)
            % create default LoggerProvider in the sdk
            testCase.startMeasuring();
            lp = opentelemetry.sdk.logs.LoggerProvider(); 
            testCase.stopMeasuring();
        end
    end
end