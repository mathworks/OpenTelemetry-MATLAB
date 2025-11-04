classdef texamples < matlab.unittest.TestCase
    % verify examples in the examples folder produce expected results

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
        function testTrace(testCase)
            % testTrace: tracing example in examples/trace folder

            % add the example folder to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "..", "examples", "trace");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % run the example
            trace_example;

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);
            
            % check generate_data span
            gendata = results{1};
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.scope.name, 'trace_example');
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.name, 'generate_data');
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.kind, 1);
            service_name_idx = find(string({gendata.resourceSpans.resource.attributes.key}) == "service.name");
            verifyNotEmpty(testCase, service_name_idx);
            verifyEqual(testCase, gendata.resourceSpans.resource.attributes(service_name_idx).value.stringValue, ...
                'OpenTelemetry-Matlab_examples');

            % check best_fit_line span
            bestfitline = results{2};
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.scope.name, 'trace_example');
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.name, 'best_fit_line');
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.kind, 1);

            % check top level function span
            toplevel = results{3};
            verifyEqual(testCase, toplevel.resourceSpans.scopeSpans.scope.name, 'trace_example');
            verifyEqual(testCase, toplevel.resourceSpans.scopeSpans.spans.name, 'trace_example');
            verifyEqual(testCase, toplevel.resourceSpans.scopeSpans.spans.kind, 1);

            % check parent child relationships
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.parentSpanId, ...
                toplevel.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.parentSpanId, ...
                toplevel.resourceSpans.scopeSpans.spans.spanId);
            verifyEmpty(testCase, toplevel.resourceSpans.scopeSpans.spans.parentSpanId);

            % check all spans belong to the same trace
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.traceId, ...
                toplevel.resourceSpans.scopeSpans.spans.traceId);
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.traceId, ...
                toplevel.resourceSpans.scopeSpans.spans.traceId);

            % check for expected timing
            verifyLessThanOrEqual(testCase, str2double(toplevel.resourceSpans.scopeSpans.spans.startTimeUnixNano), ...
                str2double(gendata.resourceSpans.scopeSpans.spans.startTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(gendata.resourceSpans.scopeSpans.spans.endTimeUnixNano), ...
                str2double(bestfitline.resourceSpans.scopeSpans.spans.startTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(bestfitline.resourceSpans.scopeSpans.spans.endTimeUnixNano), ...
                str2double(toplevel.resourceSpans.scopeSpans.spans.endTimeUnixNano));
        end

        function testLogs(testCase)
            % testLogs: logging example in examples/logs folder

            % add the example folder to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "..", "examples", "logs");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % run the example
            logs_example;

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 4);
            
            % check top level function log
            toplevel = results{1};
            verifyEqual(testCase, toplevel.resourceLogs.scopeLogs.scope.name, 'logs_example');
            verifyEqual(testCase, toplevel.resourceLogs.scopeLogs.logRecords.severityNumber, 9);
            verifyEqual(testCase, toplevel.resourceLogs.scopeLogs.logRecords.severityText, 'INFO');
            verifyEqual(testCase, toplevel.resourceLogs.scopeLogs.logRecords.body.stringValue, 'logs_example');
            verifyEmpty(testCase, toplevel.resourceLogs.scopeLogs.logRecords.traceId);
            verifyEmpty(testCase, toplevel.resourceLogs.scopeLogs.logRecords.spanId);

            % check generate_data log
            gendata = results{2};
            verifyEqual(testCase, gendata.resourceLogs.scopeLogs.scope.name, 'logs_example');
            verifyEqual(testCase, gendata.resourceLogs.scopeLogs.logRecords.severityNumber, 9);
            verifyEqual(testCase, gendata.resourceLogs.scopeLogs.logRecords.severityText, 'INFO');
            verifyEqual(testCase, gendata.resourceLogs.scopeLogs.logRecords.body.stringValue, 'generate_data');
            verifyEmpty(testCase, gendata.resourceLogs.scopeLogs.logRecords.traceId);
            verifyEmpty(testCase, gendata.resourceLogs.scopeLogs.logRecords.spanId);

            % check best_fit_line logs
            bestfitline = results{3};
            verifyEqual(testCase, bestfitline.resourceLogs.scopeLogs.scope.name, 'logs_example');
            verifyEqual(testCase, bestfitline.resourceLogs.scopeLogs.logRecords.severityNumber, 9);
            verifyEqual(testCase, bestfitline.resourceLogs.scopeLogs.logRecords.severityText, 'INFO');
            verifyEqual(testCase, bestfitline.resourceLogs.scopeLogs.logRecords.body.stringValue, 'best_fit_line');
            verifyEmpty(testCase, bestfitline.resourceLogs.scopeLogs.logRecords.traceId);
            verifyEmpty(testCase, bestfitline.resourceLogs.scopeLogs.logRecords.spanId);

            bestfitlinecoefs = results{4};
            verifyEqual(testCase, bestfitlinecoefs.resourceLogs.scopeLogs.scope.name, 'logs_example');
            verifyEqual(testCase, bestfitlinecoefs.resourceLogs.scopeLogs.logRecords.severityNumber, 9);
            verifyEqual(testCase, bestfitlinecoefs.resourceLogs.scopeLogs.logRecords.severityText, 'INFO');
            verifyNumElements(testCase, bestfitlinecoefs.resourceLogs.scopeLogs.logRecords.body.arrayValue.values, 2);
            verifyEmpty(testCase, bestfitlinecoefs.resourceLogs.scopeLogs.logRecords.traceId);
            verifyEmpty(testCase, bestfitlinecoefs.resourceLogs.scopeLogs.logRecords.spanId);

            % check for expected timing
            verifyLessThanOrEqual(testCase, str2double(toplevel.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano), ...
                str2double(gendata.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(gendata.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano), ...
                str2double(bestfitline.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(bestfitline.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano), ...
                str2double(bestfitlinecoefs.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano));
        end

        function testMetrics(testCase)
            % testMetrics: metrics_example in examples/metrics folder

            % add the example folder to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "..", "examples", "metrics");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % run the example, use only 2 iterations to keep the run time
            % reasonable for testing
            niterations = 2;
            metrics_example(niterations);

            % perform test comparisons
            results = readJsonResults(testCase);
            niter_actual = length(results);
            result_latest = results{end};   % only check the latest

            verifyEqual(testCase, result_latest.resourceMetrics.scopeMetrics.scope.name, 'metrics_example');
            instrnames = cellfun(@(x)string(x.name), result_latest.resourceMetrics.scopeMetrics.metrics);

            % check counter
            counteridx = find(instrnames == "counter");
            verifyNotEmpty(testCase, counteridx);
            counter = result_latest.resourceMetrics.scopeMetrics.metrics{counteridx};
            verifyLessThanOrEqual(testCase, counter.sum.dataPoints.asDouble, niter_actual*10);
            verifyGreaterThanOrEqual(testCase, counter.sum.dataPoints.asDouble, 0);
            verifyEqual(testCase, counter.sum.aggregationTemporality, 2); % cumulative
            verifyTrue(testCase, counter.sum.isMonotonic);

            % check updowncounter
            updowncounteridx = find(instrnames == "updowncounter");
            verifyNotEmpty(testCase, updowncounteridx);
            updowncounter = result_latest.resourceMetrics.scopeMetrics.metrics{updowncounteridx};
            verifyLessThanOrEqual(testCase, updowncounter.sum.dataPoints.asDouble, niter_actual*10);
            verifyGreaterThanOrEqual(testCase, updowncounter.sum.dataPoints.asDouble, -10*niter_actual);
            verifyEqual(testCase, updowncounter.sum.aggregationTemporality, 2); % cumulative

            % check histogram
            histogramidx = find(instrnames == "histogram");
            verifyNotEmpty(testCase, histogramidx);
            histogramobj = result_latest.resourceMetrics.scopeMetrics.metrics{histogramidx};
            verifyLessThanOrEqual(testCase, str2double(histogramobj.histogram.dataPoints.count), niter_actual);  % just check the count
            verifyEqual(testCase, histogramobj.histogram.aggregationTemporality, 2); % cumulative

            % check gauge
            gaugeidx = find(instrnames == "gauge");
            verifyNotEmpty(testCase, gaugeidx);
            gauge = result_latest.resourceMetrics.scopeMetrics.metrics{gaugeidx};
            verifyLessThanOrEqual(testCase, gauge.gauge.dataPoints.asDouble, 100);
            verifyGreaterThanOrEqual(testCase, gauge.gauge.dataPoints.asDouble, 0);
        end

        function testAsyncMetrics(testCase)
            % testAsyncMetrics: async_metrics_example in examples/metrics folder

            testCase.assumeTrue(false, "testAsyncMetrics may take too long (more than 100 seconds) to complete.");

            % add the example folder to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "..", "examples", "metrics");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % run the example, use only 2 iterations to keep the run time
            % reasonable for testing
            niterations = 2;
            async_metrics_example(niterations);

            % perform test comparisons
            results = readJsonResults(testCase);
            niter_actual = length(results);
            result_latest = results{end};   % only check the latest
            
            verifyEqual(testCase, result_latest.resourceMetrics.scopeMetrics.scope.name, 'async_metrics_example');
            instrnames = cellfun(@(x)string(x.name), result_latest.resourceMetrics.scopeMetrics.metrics);

            % check observable counter
            counteridx = find(instrnames == "observable_counter");
            verifyNotEmpty(testCase, counteridx);
            counter = result_latest.resourceMetrics.scopeMetrics.metrics{counteridx};
            verifyLessThanOrEqual(testCase, counter.sum.dataPoints.asDouble, niter_actual*10);
            verifyGreaterThanOrEqual(testCase, counter.sum.dataPoints.asDouble, 0);
            verifyEqual(testCase, counter.sum.aggregationTemporality, 2); % cumulative
            verifyTrue(testCase, counter.sum.isMonotonic);

            % check observable updowncounter
            updowncounteridx = find(instrnames == "observable_updowncounter");
            verifyNotEmpty(testCase, updowncounteridx);
            updowncounter = result_latest.resourceMetrics.scopeMetrics.metrics{updowncounteridx};
            verifyLessThanOrEqual(testCase, updowncounter.sum.dataPoints.asDouble, niter_actual*5);
            verifyGreaterThanOrEqual(testCase, updowncounter.sum.dataPoints.asDouble, -5*niter_actual);
            verifyEqual(testCase, updowncounter.sum.aggregationTemporality, 2); % cumulative

            % check observable gauge
            gaugeidx = find(instrnames == "observable_gauge");
            verifyNotEmpty(testCase, gaugeidx);
            gauge = result_latest.resourceMetrics.scopeMetrics.metrics{gaugeidx};
            verifyLessThan(testCase, gauge.gauge.dataPoints.asDouble, 60);
            verifyGreaterThanOrEqual(testCase, gauge.gauge.dataPoints.asDouble, 0);
        end

        function testWebread(testCase)
            % testWebread: webread_example in examples/webread folder

            % use default location to look for server, filter out if not
            % found
            serverfolder = fullfile(fileparts(mfilename('fullpath')), "..", "build", "examples", "webread");
            testCase.assumeTrue(logical(exist(serverfolder, "dir")), "Example server directory not found");

            % add the example folder to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "..", "examples", "webread", "matlab");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));
            server = fullfile(serverfolder, "webread_example_server");

            % start the C++ server
            testCase.applyFixture(CppServerFixture(server, testCase));
            pause(3);       % wait for server to start up

            % run the example
            webread_example();

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 2);

            serverspan = results{1};
            clientspan = results{2};

            % check C++ server span
            verifyEqual(testCase, string(serverspan.resourceSpans.scopeSpans.spans.name), "/webreadexample");
            verifyEqual(testCase, serverspan.resourceSpans.scopeSpans.spans.kind, 2);   % server
            verifyEqual(testCase, string(serverspan.resourceSpans.scopeSpans.scope.name), "http_server");
            verifyTrue(testCase, isfield(serverspan.resourceSpans.scopeSpans.spans, "events") && ...
                isscalar(serverspan.resourceSpans.scopeSpans.spans.events) && ...
                (string(serverspan.resourceSpans.scopeSpans.spans.events.name) == "Processing request"));
            service_name_idx = find(string({serverspan.resourceSpans.resource.attributes.key}) == "service.name");
            verifyNotEmpty(testCase, service_name_idx);
            verifyEqual(testCase, serverspan.resourceSpans.resource.attributes(service_name_idx).value.stringValue, ...
                'OpenTelemetry-Matlab_examples');

            % check MATLAB client span
            verifyEqual(testCase, string(clientspan.resourceSpans.scopeSpans.spans.name), "webread_example");
            verifyEqual(testCase, clientspan.resourceSpans.scopeSpans.spans.kind, 3);   % client
            verifyEqual(testCase, string(clientspan.resourceSpans.scopeSpans.scope.name), "webread_example_tracer");

            % parent child relationship
            verifyEqual(testCase, serverspan.resourceSpans.scopeSpans.spans.parentSpanId, ...
                clientspan.resourceSpans.scopeSpans.spans.spanId);  % child span
            verifyEmpty(testCase, clientspan.resourceSpans.scopeSpans.spans.parentSpanId);  % top-level span
            verifyEqual(testCase, serverspan.resourceSpans.scopeSpans.spans.traceId, ...
                clientspan.resourceSpans.scopeSpans.spans.traceId);  % check client and server belong to same trace

            % check for expected timing
            verifyLessThanOrEqual(testCase, str2double(clientspan.resourceSpans.scopeSpans.spans.startTimeUnixNano), ...
                str2double(serverspan.resourceSpans.scopeSpans.spans.startTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(serverspan.resourceSpans.scopeSpans.spans.endTimeUnixNano), ...
                str2double(clientspan.resourceSpans.scopeSpans.spans.endTimeUnixNano));
        end

        function testParallel(testCase)
            % testParallel: parfor_example in examples/parallel folder

            testCase.assumeTrue(logical(exist("parpool", "file")), "PARPOOL not found.");

            % add the example folder to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "..", "examples", "parallel");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % start a parallel pool with 2 workers
            poolobj = parpool("Processes", 2);
            
            % define cleanup
            cleanupobj = onCleanup(@()delete(poolobj));

            % run the example, doing 2 iterations with 2 workers
            parfor_example(2, 2);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);
            
            % check worker spans
            worker1 = results{1};
            verifyTrue(testCase, ismember(string(worker1.resourceSpans.scopeSpans.spans.name), ...
                ["Iteration1" "Iteration2"]));
            verifyEqual(testCase, worker1.resourceSpans.scopeSpans.spans.kind, 1);   % internal
            verifyEqual(testCase, string(worker1.resourceSpans.scopeSpans.scope.name), "parfor_example");
            service_name_idx = find(string({worker1.resourceSpans.resource.attributes.key}) == "service.name");
            verifyNotEmpty(testCase, service_name_idx);
            verifyEqual(testCase, worker1.resourceSpans.resource.attributes(service_name_idx).value.stringValue, ...
                'OpenTelemetry-Matlab_examples');

            worker2 = results{2};
            verifyTrue(testCase, ismember(string(worker2.resourceSpans.scopeSpans.spans.name), ...
                ["Iteration1" "Iteration2"]));
            verifyEqual(testCase, worker2.resourceSpans.scopeSpans.spans.kind, 1);   % internal
            verifyEqual(testCase, string(worker2.resourceSpans.scopeSpans.scope.name), "parfor_example");

            % top level span
            toplevel = results{3};
            verifyEqual(testCase, string(toplevel.resourceSpans.scopeSpans.spans.name), "main function");
            verifyEqual(testCase, toplevel.resourceSpans.scopeSpans.spans.kind, 1);   % internal
            verifyEqual(testCase, string(toplevel.resourceSpans.scopeSpans.scope.name), "parfor_example");

            % parent child relationship
            verifyEqual(testCase, worker1.resourceSpans.scopeSpans.spans.parentSpanId, ...
                toplevel.resourceSpans.scopeSpans.spans.spanId);  % child span
            verifyEqual(testCase, worker2.resourceSpans.scopeSpans.spans.parentSpanId, ...
                toplevel.resourceSpans.scopeSpans.spans.spanId);  % child span
            verifyEmpty(testCase, toplevel.resourceSpans.scopeSpans.spans.parentSpanId);  % top-level span
            verifyEqual(testCase, worker1.resourceSpans.scopeSpans.spans.traceId, ...
                toplevel.resourceSpans.scopeSpans.spans.traceId);  % check belong to same trace
            verifyEqual(testCase, worker2.resourceSpans.scopeSpans.spans.traceId, ...
                toplevel.resourceSpans.scopeSpans.spans.traceId);

            % check for expected timing
            verifyLessThanOrEqual(testCase, str2double(toplevel.resourceSpans.scopeSpans.spans.startTimeUnixNano), ...
                str2double(worker1.resourceSpans.scopeSpans.spans.startTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(worker1.resourceSpans.scopeSpans.spans.endTimeUnixNano), ...
                str2double(toplevel.resourceSpans.scopeSpans.spans.endTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(toplevel.resourceSpans.scopeSpans.spans.startTimeUnixNano), ...
                str2double(worker2.resourceSpans.scopeSpans.spans.startTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(worker2.resourceSpans.scopeSpans.spans.endTimeUnixNano), ...
                str2double(toplevel.resourceSpans.scopeSpans.spans.endTimeUnixNano));
        end

        function testAutoTrace(testCase)
            % testAutoTrace: AutoTrace example in examples/autotrace folder

            % add the example folder to the path
            examplefolder = fullfile(fileparts(mfilename('fullpath')), "..", "examples", "autotrace");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(examplefolder));

            % run the example
            run_example;

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 3);
            
            % check generate_data span
            gendata = results{1};
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.scope.name, 'autotrace_example');
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.name, 'generate_data');
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.kind, 1);
            service_name_idx = find(string({gendata.resourceSpans.resource.attributes.key}) == "service.name");
            verifyNotEmpty(testCase, service_name_idx);
            verifyEqual(testCase, gendata.resourceSpans.resource.attributes(service_name_idx).value.stringValue, ...
                'OpenTelemetry-Matlab_examples');

            % check best_fit_line span
            bestfitline = results{2};
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.scope.name, 'autotrace_example');
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.name, 'best_fit_line');
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.kind, 1);

            % check top level function span
            toplevel = results{3};
            verifyEqual(testCase, toplevel.resourceSpans.scopeSpans.scope.name, 'autotrace_example');
            verifyEqual(testCase, toplevel.resourceSpans.scopeSpans.spans.name, 'autotrace_example');
            verifyEqual(testCase, toplevel.resourceSpans.scopeSpans.spans.kind, 1);

            % check parent child relationships
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.parentSpanId, ...
                toplevel.resourceSpans.scopeSpans.spans.spanId);
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.parentSpanId, ...
                toplevel.resourceSpans.scopeSpans.spans.spanId);
            verifyEmpty(testCase, toplevel.resourceSpans.scopeSpans.spans.parentSpanId);

            % check all spans belong to the same trace
            verifyEqual(testCase, gendata.resourceSpans.scopeSpans.spans.traceId, ...
                toplevel.resourceSpans.scopeSpans.spans.traceId);
            verifyEqual(testCase, bestfitline.resourceSpans.scopeSpans.spans.traceId, ...
                toplevel.resourceSpans.scopeSpans.spans.traceId);

            % check for expected timing
            verifyLessThanOrEqual(testCase, str2double(toplevel.resourceSpans.scopeSpans.spans.startTimeUnixNano), ...
                str2double(gendata.resourceSpans.scopeSpans.spans.startTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(gendata.resourceSpans.scopeSpans.spans.endTimeUnixNano), ...
                str2double(bestfitline.resourceSpans.scopeSpans.spans.startTimeUnixNano));
            verifyLessThanOrEqual(testCase, str2double(bestfitline.resourceSpans.scopeSpans.spans.endTimeUnixNano), ...
                str2double(toplevel.resourceSpans.scopeSpans.spans.endTimeUnixNano));
        end
    end
end
