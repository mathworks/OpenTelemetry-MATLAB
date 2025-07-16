classdef tlogs_sdk < matlab.unittest.TestCase
    % tests for logging SDK (log record processors, exporters, resource)

    % Copyright 2024-2025 The MathWorks, Inc.

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
            % add the utils and fixtures folder to the path
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
        function testOtlpFileExporter(testCase)
            % testOtlpFileExporter: use a file exporter to write to files

            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpFileLogRecordExporter", "class")), ...
                "Otlp file exporter must be installed.");

            % create temporary folder to write the output files
            folderfixture = testCase.applyFixture(...
                matlab.unittest.fixtures.TemporaryFolderFixture);

            % create file exporter
            output = fullfile(folderfixture.Folder,"output%n.json");
            alias = fullfile(folderfixture.Folder,"output_latest.json");
            exp = opentelemetry.exporters.otlp.OtlpFileLogRecordExporter(...
                FileName=output, AliasName=alias);

            lp = opentelemetry.sdk.logs.LoggerProvider(...
                opentelemetry.sdk.logs.SimpleLogRecordProcessor(exp));

            loggername = "foo";
            logseverity = "debug";
            logmessage = "bar";
            lg = getLogger(lp, loggername);
            emitLogRecord(lg, logseverity, logmessage);

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            clear("lg", "lp");
            resultstxt = readlines(alias);
            results = jsondecode(resultstxt(1));

            % check logger name, log body and severity
            verifyEqual(testCase, string(results.resourceLogs.scopeLogs.scope.name), loggername);
            verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.severityText), upper(logseverity));
            verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.body.stringValue), logmessage);
        end
       
        function testAddLogRecordProcessor(testCase)
            % testAddLogRecordProcessor: addLogRecordProcessor method
            loggername = "foo";
            logbody = "bar";
            processor1 = opentelemetry.sdk.logs.SimpleLogRecordProcessor;
            processor2 = opentelemetry.sdk.logs.SimpleLogRecordProcessor;
            p = opentelemetry.sdk.logs.LoggerProvider(processor1);
            p.addLogRecordProcessor(processor2);
            lg = p.getLogger(loggername);
            lg.emitLogRecord("debug", logbody);

            % verify if the provider has two log processors attached
            processor_count = numel(p.LogRecordProcessor);
            verifyEqual(testCase,processor_count, 2);

            % verify if the json results has two exported instances after
            % emitting a single log record
            forceFlush(p, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            result_count = numel(results);
            verifyEqual(testCase,result_count, 2);
        end

        function testBatchLogRecordProcessor(testCase)
            % testBatchLogRecordProcessor: setting properties of
            % BatchLogRecordProcessor
            loggername = "foo";
            logseverity = "debug";
            logbody = "bar";
            queuesize = 500;
            delay = seconds(2);
            batchsize = 50;
            b = opentelemetry.sdk.logs.BatchLogRecordProcessor;
            b.MaximumQueueSize = queuesize;
            b.ScheduledDelay = delay;
            b.MaximumExportBatchSize = batchsize;
            
            % verify properties modified successfully
            verifyEqual(testCase, b.MaximumQueueSize, queuesize);
            verifyEqual(testCase, b.ScheduledDelay, delay);
            verifyEqual(testCase, b.MaximumExportBatchSize, batchsize)
            verifyEqual(testCase, class(b.LogRecordExporter), ...
                class(opentelemetry.exporters.otlp.defaultLogRecordExporter));

            p = opentelemetry.sdk.logs.LoggerProvider(b);
            lg = p.getLogger(loggername);
            lg.emitLogRecord(logseverity, logbody);

            % verify log body and severity
            forceFlush(p, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            results = results{1};
            verifyEqual(testCase, string(results.resourceLogs.scopeLogs.scope.name), loggername);
            verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.severityText), upper(logseverity));
            verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.body.stringValue), logbody);
        end

        function testCustomResource(testCase)
            % testCustomResource: check custom resources are included in
            % emitted log record
            customkeys = ["foo" "bar"];
            customvalues = [1 5];
            lp = opentelemetry.sdk.logs.LoggerProvider("Resource", dictionary(customkeys, customvalues)); 
            lg = getLogger(lp, "baz");
            emitLogRecord(lg, "debug", "qux");

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            results = results{1};

            resourcekeys = string({results.resourceLogs.resource.attributes.key});
            for i = length(customkeys)
                idx = find(resourcekeys == customkeys(i));
                verifyNotEmpty(testCase, idx);
                verifyEqual(testCase, results.resourceLogs.resource.attributes(idx).value.doubleValue, customvalues(i));
            end
        end

        function testShutdown(testCase)
            % testShutdown: shutdown method should stop exporting
            % of log records
            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "foo");

            % emit a log record 
            logbody = "bar";
            emitLogRecord(lg, "info", logbody);

            % shutdown the logger provider
            forceFlush(lp, testCase.ForceFlushTimeout);
            verifyTrue(testCase, shutdown(lp));

            % suppress internal error logs about log export failure
            nologs = SuppressInternalLogs; %#ok<NASGU>
            
            % emit another log record
            emitLogRecord(lg, "info", "quux");

            % verify only the first log record was emitted
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceLogs.scopeLogs.logRecords.body.stringValue), logbody);
        end

        function testCleanupSdk(testCase)
            % testCleanupSdk: shutdown an SDK logger provider through the Cleanup class
            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "foo");

            % emit a log record 
            logbody = "bar";
            emitLogRecord(lg, "warn", logbody);

            % shutdown the SDK logger provider through the Cleanup class
            forceFlush(lp, testCase.ForceFlushTimeout);
            verifyTrue(testCase, opentelemetry.sdk.common.Cleanup.shutdown(lp));

            % suppress internal error logs about log export failure
            nologs = SuppressInternalLogs; %#ok<NASGU>

            % emit another log record
            emitLogRecord(lg, "warn", "quux");

            % verify only the first log record was recorded
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceLogs.scopeLogs.logRecords.body.stringValue), logbody);
        end

        function testCleanupApi(testCase)
            % testCleanupApi: shutdown an API logger provider through the Cleanup class  
            lp = opentelemetry.sdk.logs.LoggerProvider();
            testCase.applyFixture(LoggerProviderFixture(lp));  % set global instance of logger provider
            lp_api = opentelemetry.logs.Provider.getLoggerProvider();
            lg = getLogger(lp_api, "foo");

            % emit a log record 
            logbody = "bar";
            emitLogRecord(lg, "error", logbody);

            % shutdown the API logger provider through the Cleanup class
            opentelemetry.sdk.common.Cleanup.forceFlush(lp_api, testCase.ForceFlushTimeout);
            verifyTrue(testCase, opentelemetry.sdk.common.Cleanup.shutdown(lp_api));

            % suppress internal error logs about log export failure
            nologs = SuppressInternalLogs; %#ok<NASGU>

            % emit another log record
            emitLogRecord(lg, "error", "quux");

            % verify only the first log record was recorded
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);
            verifyEqual(testCase, string(results{1}.resourceLogs.scopeLogs.logRecords.body.stringValue), logbody);
        end
    end
end