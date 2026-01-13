classdef tbuildtoolplugin < matlab.unittest.TestCase
    properties
        OtelConfigFile
        JsonFile
        PidFile
        ListPid
        ReadPidList
        ExtractPid
        Sigint
        Sigterm
        OtelcolName
        Otelcol

        BuildRunner
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            % add the utils, callbacks, and fixtures folders to the path
            folders = fullfile(fileparts(mfilename('fullpath')), ["utils" "callbacks" "fixtures"]);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folders));
            commonSetupOnce(testCase);
        end
    end

    methods (TestMethodSetup)
        function setup(testCase)
            commonSetup(testCase);
        end

        function onlyTestIfgRPCIsInstalled(testCase)
            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpGrpcSpanExporter", "class")), ...
                "Otlp gRPC exporter must be installed.");
        end
        
        function createBuildRunner(testCase)
            plugin = matlab.buildtool.plugins.OpenTelemetryPlugin();
            testCase.BuildRunner = matlab.buildtool.BuildRunner.withNoPlugins();
            testCase.BuildRunner.addPlugin(plugin);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            commonTeardown(testCase);
        end
    end

    methods (Test)
        function pluginIsAddedAsADefaultPluginInNewReleases(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2026a"));

            runner = matlab.buildtool.BuildRunner.withDefaultPlugins();
            tf = arrayfun(@(x)isa(x, "matlab.buildtool.plugins.OpenTelemetryPlugin"), runner.Plugins);
            testCase.verifyTrue(any(tf));
        end

        function pluginIsNotAddedAsADefaultPluginInOlderReleases(testCase)
            testCase.assumeTrue(isMATLABReleaseOlderThan("R2026a"));

            runner = matlab.buildtool.BuildRunner.withDefaultPlugins();
            tf = arrayfun(@(x)isa(x, "matlab.buildtool.plugins.OpenTelemetryPlugin"), runner.Plugins);
            testCase.verifyFalse(any(tf));
        end

        function runOneTaskHasCorrectSpans(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2026a"));

            % Create plan with 1 successful task
            plan = buildplan();
            plan("task") = matlab.buildtool.Task();

            % Run build
            testCase.BuildRunner.run(plan, "task");

            % Get results
            results = readJsonResults(testCase);
            spanData = results{1}.resourceSpans;

            % Verify spans
            spans = spanData.scopeSpans;
            testCase.verifyEqual(numel(spans), 2);

            % First span is overall build span
            buildSpan = spanData.scopeSpans(1).spans;
            testCase.verifyEqual(string(buildSpan.name), "buildtool");
            testCase.verifyEqual(buildSpan.status.code, 1);

            % Build span attributes
            att1.key = 'otel.library.name';
            att1.value.stringValue = 'buildtool';

            att2.key = 'span.kind';
            att2.value.stringValue = 'internal';

            att3.key = 'internal.span.format';
            att3.value.stringValue = 'proto';

            att4.key = 'buildtool.tasks';
            att4.value.doubleValue = 1;

            att5.key = 'buildtool.tasks.successful';
            att5.value.stringValue = 'task';

            att6.key = 'buildtool.tasks.failed';
            att6.value.arrayValue = struct();

            sizeZero.doubleValue = 0;
            att7.key = 'buildtool.tasks.failed.size';
            att7.value.arrayValue.values = [sizeZero; sizeZero];

            att8.key = 'buildtool.tasks.skipped';
            att8.value.arrayValue = struct();

            att9.key = 'buildtool.tasks.skipped.size';
            att9.value.arrayValue.values = [sizeZero; sizeZero];

            att10.key = 'buildtool.build.successes';
            att10.value.doubleValue = 1;

            att11.key = 'buildtool.build.failures';
            att11.value.doubleValue = 0;

            att12.key = 'buildtool.build.skips';
            att12.value.doubleValue = 0;

            expected = [ ...
                att1, ...
                att2, ...
                att3, ...
                att4, ...
                att5, ...
                att6, ...
                att7, ...
                att8, ...
                att9, ...
                att10, ...
                att11, ...
                att12, ...
            ]';
            
            testCase.verifyEqual(buildSpan.attributes, expected);

            % Second span is "task" span
            taskSpan = spanData.scopeSpans(2).spans;

            testCase.verifyEqual(string(taskSpan.name), "task");
            testCase.verifyEqual(taskSpan.status.code, 1);
            testCase.verifyEqual(taskSpan.parentSpanId, buildSpan.spanId);

            % Task span attributes
            tAtt1.key = 'otel.library.name';
            tAtt1.value.stringValue = 'task';

            tAtt2.key = 'span.kind';
            tAtt2.value.stringValue = 'internal';

            tAtt3.key = 'internal.span.format';
            tAtt3.value.stringValue = 'proto';

            tAtt4.key = 'buildtool.task.name';
            tAtt4.value.stringValue = 'task';

            tAtt5.key = 'buildtool.task.description';
            tAtt5.value.stringValue = '';

            tAtt6.key = 'buildtool.task.successful';
            tAtt6.value.boolValue = true;

            tAtt7.key = 'buildtool.task.failed';
            tAtt7.value.boolValue = false;

            tAtt8.key = 'buildtool.task.skipped';
            tAtt8.value.boolValue = false;

            expected = [ ...
                tAtt1, ...
                tAtt2, ...
                tAtt3, ...
                tAtt4, ...
                tAtt5, ...
                tAtt6, ...
                tAtt7, ...
                tAtt8, ...                
            ]';

            testCase.verifyEqual(taskSpan.attributes, expected);
        end

        function runOneTaskHasCorrectMetrics(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2026a"));

            % Create plan with 1 successful task
            plan = buildplan();
            plan("task") = matlab.buildtool.Task();

            % Run build
            testCase.BuildRunner.run(plan, "task");

            % Get results
            results = readJsonResults(testCase);
            metricData = results{2}.resourceMetrics;

            metrics = metricData.scopeMetrics.metrics;

            % Order appears to be deterministic on my machine.
            testCase.verifyEqual(metrics(1).name, 'buildtool.build.failures');
            testCase.verifyEqual(metrics(1).sum.dataPoints.asDouble, 0);

            testCase.verifyEqual(metrics(2).name, 'buildtool.build.successes');
            testCase.verifyEqual(metrics(2).sum.dataPoints.asDouble, 1);

            testCase.verifyEqual(metrics(3).name, 'buildtool.tasks.skipped');
            testCase.verifyEqual(metrics(3).sum.dataPoints.asDouble, 0);

            testCase.verifyEqual(metrics(4).name, 'buildtool.tasks.failed');
            testCase.verifyEqual(metrics(4).sum.dataPoints.asDouble, 0);

            testCase.verifyEqual(metrics(5).name, 'buildtool.tasks.successful');
            testCase.verifyEqual(metrics(5).sum.dataPoints.asDouble, 1);
        end

        function runningSeveralTasksProducesCorrectSpans(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2026a"));

            % Create plan with 3 successful tasks and a failing task
            plan = buildplan();
            plan("t1") = matlab.buildtool.Task();
            plan("t2") = matlab.buildtool.Task(Dependencies="t1");
            plan("t3") = matlab.buildtool.Task(Dependencies="t2");
            plan("error") = matlab.buildtool.Task(Actions=@(~)error("bam"), Dependencies="t3");

            % Run build
            testCase.BuildRunner.run(plan, "error");

            % Get results
            results = readJsonResults(testCase);
            spanData = results{1}.resourceSpans;

            % Verify spans
            spans = spanData.scopeSpans;
            testCase.verifyEqual(numel(spans), 5);

            % First span is overall build span
            buildSpan = findSpan("buildtool", spans);
            testCase.verifyEqual(string(buildSpan.name), "buildtool");
            testCase.verifyEqual(buildSpan.status.code, 2); % Build should fail

            % Build span attributes
            att1.key = 'otel.library.name';
            att1.value.stringValue = 'buildtool';

            att2.key = 'span.kind';
            att2.value.stringValue = 'internal';

            att3.key = 'internal.span.format';
            att3.value.stringValue = 'proto';

            att4.key = 'buildtool.tasks';
            att4.value.doubleValue = 4;

            val1.stringValue = 't1';
            val2.stringValue = 't2';
            val3.stringValue = 't3';
            att5.key = 'buildtool.tasks.successful';
            att5.value.arrayValue.values = [val1; val2; val3];
            
            size1.doubleValue = 1;
            size3.doubleValue = 3;
            att6.key = 'buildtool.tasks.successful.size';
            att6.value.arrayValue.values = [size1; size3];

            att7.key = 'buildtool.tasks.failed';
            att7.value.stringValue = 'error';

            att8.key = 'buildtool.tasks.skipped';
            att8.value.arrayValue = struct();

            sizeZero.doubleValue = 0;
            att9.key = 'buildtool.tasks.skipped.size';
            att9.value.arrayValue.values = [sizeZero; sizeZero];

            att10.key = 'buildtool.build.successes';
            att10.value.doubleValue = 3;

            att11.key = 'buildtool.build.failures';
            att11.value.doubleValue = 1;

            att12.key = 'buildtool.build.skips';
            att12.value.doubleValue = 0;

            expected = [ ...
                att1, ...
                att2, ...
                att3, ...
                att4, ...
                att5, ...
                att6, ...
                att7, ...
                att8, ...
                att9, ...
                att10, ...
                att11, ...
                att12, ...
            ]';

            testCase.verifyEqual(buildSpan.attributes, expected);

            % "t1" span
            taskSpan = findSpan("t1", spans);

            testCase.verifyEqual(string(taskSpan.name), "t1");
            testCase.verifyEqual(taskSpan.status.code, 1);
            testCase.verifyEqual(taskSpan.parentSpanId, buildSpan.spanId);

            % Task span attributes
            tAtt1.key = 'otel.library.name';
            tAtt1.value.stringValue = 't1';

            tAtt2.key = 'span.kind';
            tAtt2.value.stringValue = 'internal';

            tAtt3.key = 'internal.span.format';
            tAtt3.value.stringValue = 'proto';

            tAtt4.key = 'buildtool.task.name';
            tAtt4.value.stringValue = 't1';

            tAtt5.key = 'buildtool.task.description';
            tAtt5.value.stringValue = '';

            tAtt6.key = 'buildtool.task.successful';
            tAtt6.value.boolValue = true;

            tAtt7.key = 'buildtool.task.failed';
            tAtt7.value.boolValue = false;

            tAtt8.key = 'buildtool.task.skipped';
            tAtt8.value.boolValue = false;

            expected = [ ...
                tAtt1, ...
                tAtt2, ...
                tAtt3, ...
                tAtt4, ...
                tAtt5, ...
                tAtt6, ...
                tAtt7, ...
                tAtt8, ...                
                ]';

            testCase.verifyEqual(taskSpan.attributes, expected);

            % "t2" span
            taskSpan = findSpan("t2", spans);

            testCase.verifyEqual(string(taskSpan.name), "t2");
            testCase.verifyEqual(taskSpan.status.code, 1);
            testCase.verifyEqual(taskSpan.parentSpanId, buildSpan.spanId);

            % Task span attributes
            tAtt1.key = 'otel.library.name';
            tAtt1.value.stringValue = 't2';

            tAtt2.key = 'span.kind';
            tAtt2.value.stringValue = 'internal';

            tAtt3.key = 'internal.span.format';
            tAtt3.value.stringValue = 'proto';

            tAtt4.key = 'buildtool.task.name';
            tAtt4.value.stringValue = 't2';

            tAtt5.key = 'buildtool.task.description';
            tAtt5.value.stringValue = '';

            tAtt6.key = 'buildtool.task.successful';
            tAtt6.value.boolValue = true;

            tAtt7.key = 'buildtool.task.failed';
            tAtt7.value.boolValue = false;

            tAtt8.key = 'buildtool.task.skipped';
            tAtt8.value.boolValue = false;

            expected = [ ...
                tAtt1, ...
                tAtt2, ...
                tAtt3, ...
                tAtt4, ...
                tAtt5, ...
                tAtt6, ...
                tAtt7, ...
                tAtt8, ...                
                ]';

            testCase.verifyEqual(taskSpan.attributes, expected);

            % "t3" span
            taskSpan = findSpan("t3", spans);

            testCase.verifyEqual(string(taskSpan.name), "t3");
            testCase.verifyEqual(taskSpan.status.code, 1);
            testCase.verifyEqual(taskSpan.parentSpanId, buildSpan.spanId);

            % Task span attributes
            tAtt1.key = 'otel.library.name';
            tAtt1.value.stringValue = 't3';

            tAtt2.key = 'span.kind';
            tAtt2.value.stringValue = 'internal';

            tAtt3.key = 'internal.span.format';
            tAtt3.value.stringValue = 'proto';

            tAtt4.key = 'buildtool.task.name';
            tAtt4.value.stringValue = 't3';

            tAtt5.key = 'buildtool.task.description';
            tAtt5.value.stringValue = '';

            tAtt6.key = 'buildtool.task.successful';
            tAtt6.value.boolValue = true;

            tAtt7.key = 'buildtool.task.failed';
            tAtt7.value.boolValue = false;

            tAtt8.key = 'buildtool.task.skipped';
            tAtt8.value.boolValue = false;

            expected = [ ...
                tAtt1, ...
                tAtt2, ...
                tAtt3, ...
                tAtt4, ...
                tAtt5, ...
                tAtt6, ...
                tAtt7, ...
                tAtt8, ...                
                ]';

            testCase.verifyEqual(taskSpan.attributes, expected);

            % "error" span
            taskSpan = findSpan("error", spans);

            testCase.verifyEqual(string(taskSpan.name), "error");
            testCase.verifyEqual(taskSpan.status.code, 2); % Should error
            testCase.verifyEqual(taskSpan.parentSpanId, buildSpan.spanId);

            % Task span attributes
            tAtt1.key = 'otel.library.name';
            tAtt1.value.stringValue = 'error';

            tAtt2.key = 'span.kind';
            tAtt2.value.stringValue = 'internal';

            tAtt3.key = 'internal.span.format';
            tAtt3.value.stringValue = 'proto';

            tAtt4.key = 'buildtool.task.name';
            tAtt4.value.stringValue = 'error';

            tAtt5.key = 'buildtool.task.description';
            tAtt5.value.stringValue = '';

            tAtt6.key = 'buildtool.task.successful';
            tAtt6.value.boolValue = false;

            tAtt7.key = 'buildtool.task.failed';
            tAtt7.value.boolValue = true;

            tAtt8.key = 'buildtool.task.skipped';
            tAtt8.value.boolValue = false;

            expected = [ ...
                tAtt1, ...
                tAtt2, ...
                tAtt3, ...
                tAtt4, ...
                tAtt5, ...
                tAtt6, ...
                tAtt7, ...
                tAtt8, ...                
                ]';

            testCase.verifyEqual(taskSpan.attributes, expected);
        end

        function runningSeveralTasksProducesCorrectMetrics(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2026a"));

            % Create plan with 3 successful tasks and a failing task
            plan = buildplan();
            plan("t1") = matlab.buildtool.Task();
            plan("t2") = matlab.buildtool.Task(Dependencies="t1");
            plan("t3") = matlab.buildtool.Task(Dependencies="t2");
            plan("error") = matlab.buildtool.Task(Actions=@(~)error("bam"), Dependencies="t3");

            % Run build
            testCase.BuildRunner.run(plan, "error");

            % Get results
            results = readJsonResults(testCase);
            metricData = results{2}.resourceMetrics;

            metrics = metricData.scopeMetrics.metrics;

            % Order appears to be deterministic on my machine.
            testCase.verifyEqual(metrics(1).name, 'buildtool.build.failures');
            testCase.verifyEqual(metrics(1).sum.dataPoints.asDouble, 1);

            testCase.verifyEqual(metrics(2).name, 'buildtool.build.successes');
            testCase.verifyEqual(metrics(2).sum.dataPoints.asDouble, 0);

            testCase.verifyEqual(metrics(3).name, 'buildtool.tasks.skipped');
            testCase.verifyEqual(metrics(3).sum.dataPoints.asDouble, 0);

            testCase.verifyEqual(metrics(4).name, 'buildtool.tasks.failed');
            testCase.verifyEqual(metrics(4).sum.dataPoints.asDouble, 1);

            testCase.verifyEqual(metrics(5).name, 'buildtool.tasks.successful');
            testCase.verifyEqual(metrics(5).sum.dataPoints.asDouble, 3);
        end
    end
end

function span = findSpan(name, spans)
    for s = spans'
        realSpan = s.spans;
        if (strcmp(name, realSpan.name))
            span = realSpan;
            return;
        end
    end

    error("No span found");
end