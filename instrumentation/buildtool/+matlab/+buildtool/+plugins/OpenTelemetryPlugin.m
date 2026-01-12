classdef OpenTelemetryPlugin < matlab.buildtool.plugins.BuildRunnerPlugin

    % Copyright 2026 The MathWorks, Inc.

    methods(Access = protected)
        function runBuild(plugin, pluginData)
            % Configure by attaching to span if passed in via environment
            % variable, and propagating baggage
            configureOTel();

            % Attributes
            otelAttributes = dictionary( ...
                [ ...
                    "otel.library.name", ...
                    "span.kind", ...
                    "internal.span.format", ...
                ], ...
                [ ...
                    "buildtool", ...
                    "internal", ...
                    "proto", ...
                ] ...
            );

            tr = opentelemetry.trace.getTracer("buildtool");
            sp = tr.startSpan("buildtool", Attributes=otelAttributes);
            scope = makeCurrent(sp); %#ok<NASGU>

            % Run build
            runBuild@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);

            % Update status
            if pluginData.BuildResult.Failed
                sp.setStatus("Error", "Build completed, results not successful");
            else
                sp.setStatus("Ok");
            end

            % Results-based attributes
            taskResults = pluginData.BuildResult.TaskResults;
            successful = [taskResults([taskResults.Successful]).Name];
            failed = [taskResults([taskResults.Failed]).Name];
            skipped = [taskResults([taskResults.Skipped]).Name];

            sp.setAttributes( ...
                "buildtool.tasks", numel(pluginData.BuildResult.TaskResults), ...
                "buildtool.tasks.successful", successful, ...
                "buildtool.tasks.failed", failed, ...
                "buildtool.tasks.skipped", skipped, ...
                "buildtool.build.successes", numel(successful), ...
                "buildtool.build.failures", numel(failed), ...
                "buildtool.build.skips", numel(skipped) ...
            );

            % Update metrics
            meter = opentelemetry.metrics.getMeter("buildtool");
            successes = meter.createCounter("buildtool.tasks.successful");
            failures = meter.createCounter("buildtool.tasks.failed");
            skips = meter.createCounter("buildtool.tasks.skipped");
            buildSuccesses = meter.createCounter("buildtool.build.successes");
            buildFailures = meter.createCounter("buildtool.build.failures");

            successes.add(numel(successful));
            failures.add(numel(failed));
            skips.add(numel(skipped));
            buildSuccesses.add(double(~pluginData.BuildResult.Failed));
            buildFailures.add(double(pluginData.BuildResult.Failed));

            cleanupOTel(sp);
        end

        function runTask(plugin, pluginData)
            % TODO:
            %  - buildtool.task.outputs
            %  - buildtool.task.inputs

            % Definitions
            taskName = pluginData.Name;
            taskDescription = pluginData.Tasks.Description;

            % Attributes
            otelAttributes = dictionary( ...
                [ ...
                    "otel.library.name", ...
                    "span.kind", ...
                    "internal.span.format", ...
                    "buildtool.task.name", ...
                    "buildtool.task.description", ...
                ], ...
                [ ...
                    taskName, ...
                    "internal", ...
                    "proto", ...
                    taskName, ...
                    taskDescription ...
                ] ...
            );

            tr = opentelemetry.trace.getTracer(taskName);
            sp = tr.startSpan(taskName, Attributes=otelAttributes);
            scope = makeCurrent(sp); %#ok<NASGU>

            % Run task
            runTask@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);

            % Set results-based attributes
            resultAttributes = dictionary( ...
                [ ...
                    "buildtool.task.successful", ...
                    "buildtool.task.failed", ...
                    "buildtool.task.skipped" ...
                ], ...
                [ ...
                    pluginData.TaskResults.Successful, ...
                    pluginData.TaskResults.Failed, ...
                    pluginData.TaskResults.Skipped ...
                ] ...
            );
            sp.setAttributes(resultAttributes);

            % Update span status
            if pluginData.TaskResults.Successful
                sp.setStatus("Ok");
            else
                sp.setStatus("Error", "Task completed, results not successful");
            end

            sp.endSpan();
        end
    end
end

% Use the same configuration as PADV
function extcontextscope = configureOTel()
% populate resource attributes
otelservicename = "buildtool";
otelresource = dictionary("service.name", otelservicename);

% baggage propagation
otelbaggage = getenv("BAGGAGE");
if ~isempty(otelbaggage)
    otelbaggage = split(split(string(otelbaggage),','), "=");
    otelresource = insert(otelresource, otelbaggage(:,1), otelbaggage(:,2));
end

% check for passed in external context
extcontextscope = [];
traceid = getenv("TRACE_ID");
spanid = getenv("SPAN_ID");
if ~isempty(traceid) && ~isempty(spanid)
    spcontext = opentelemetry.trace.SpanContext(traceid, spanid);
    extcontextscope = makeCurrent(spcontext);
end

% tracer provider
otelspexp = opentelemetry.exporters.otlp.OtlpGrpcSpanExporter; % use gRPC because Otel plugin for Jenkins only use gRPC
otelspproc = opentelemetry.sdk.trace.BatchSpanProcessor(otelspexp);
oteltp = opentelemetry.sdk.trace.TracerProvider(otelspproc, Resource=otelresource);
setTracerProvider(oteltp);

% meter provider
otelmexp = opentelemetry.exporters.otlp.OtlpGrpcMetricExporter; % use gRPC because Otel plugin for Jenkins only use gRPC
otelmread = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(otelmexp);
otelmp = opentelemetry.sdk.metrics.MeterProvider(otelmread, Resource=otelresource);
setMeterProvider(otelmp);

% logger provider
otellgexp = opentelemetry.exporters.otlp.OtlpGrpcLogRecordExporter; % use gRPC because Otel plugin for Jenkins only use gRPC
otellgproc = opentelemetry.sdk.logs.BatchLogRecordProcessor(otellgexp);
otellp = opentelemetry.sdk.logs.LoggerProvider(otellgproc, Resource=otelresource);
setLoggerProvider(otellp);
end

% Use the same cleanup as PADV
function cleanupOTel(span)

timeout = 5;

% end the input span before cleaning up
if nargin > 0
    endSpan(span);
end

% tracer provider
oteltp = opentelemetry.trace.Provider.getTracerProvider;
opentelemetry.sdk.common.Cleanup.forceFlush(oteltp, timeout);
opentelemetry.sdk.common.Cleanup.shutdown(oteltp);

% meter provider
otelmp = opentelemetry.metrics.Provider.getMeterProvider;
opentelemetry.sdk.common.Cleanup.forceFlush(otelmp, timeout);
opentelemetry.sdk.common.Cleanup.shutdown(otelmp);

% logger provider
otellp = opentelemetry.logs.Provider.getLoggerProvider;
opentelemetry.sdk.common.Cleanup.forceFlush(otellp, timeout);
opentelemetry.sdk.common.Cleanup.shutdown(otellp);
end