classdef BatchSpanProcessor < opentelemetry.sdk.trace.SpanProcessor
% Batch span processor creates batches of spans and passes them to an exporter.

% Copyright 2023 The MathWorks, Inc.

    properties
        MaximumQueueSize (1,1) double = 2048       % Maximum queue size. After queue size is reached, spans are dropped.
        ScheduledDelay (1,1) duration = seconds(5) % Time interval between span exports
        MaximumExportBatchSize (1,1) double = 512  % Maximum batch size to export. 
    end

    methods
        function obj = BatchSpanProcessor(spanexporter, optionnames, optionvalues)
            % Batch span processor creates batches of spans and passes them to an exporter.
            %    BSP = OPENTELEMETRY.SDK.TRACE.BATCHSPANPROCESSOR creates a 
            %    batch span processor that uses an OTLP HTTP exporter, which 
            %    exports spans in OpenTelemetry Protocol (OTLP) format through HTTP.
            %
            %    BSP = OPENTELEMETRY.SDK.TRACE.BATCHSPANPROCESSOR(EXP) specifies 
            %    the span exporter. Supported span exporters are OTLP HTTP 
            %    exporter and OTLP gRPC exporter.
            %    
            %    BSP = OPENTELEMETRY.SDK.TRACE.BATCHSPANPROCESSOR(EXP, PARAM1, 
            %    VALUE1, PARAM2, VALUE2, ...) specifies optional parameter 
            %    name/value pairs. Parameters are:
            %       "MaximumQueueSize"  - Maximum queue size. After queue
            %                             size is reached, spans are dropped. 
            %                             Default value is 2048.
            %       "ScheduledDelay"    - Time interval between span
            %                             exports. Default interval is 5 seconds.
            %       "MaximumExportBatchSize"  - Maximum batch size to export.
            %                                   Default size is 512.
            %                        
            %    See also OPENTELEMETRY.SDK.TRACE.SIMPLESPANPROCESSOR, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER, 
            %    OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER  
            arguments
      	       spanexporter {mustBeA(spanexporter, "opentelemetry.sdk.trace.SpanExporter")} = ...
                   opentelemetry.exporters.otlp.defaultSpanExporter()
            end
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            obj = obj@opentelemetry.sdk.trace.SpanProcessor(spanexporter, ...
                "libmexclass.opentelemetry.sdk.BatchSpanProcessorProxy");

            validnames = ["MaximumQueueSize", "ScheduledDelay", "MaximumExportBatchSize"];
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                obj.(namei) = valuei;
            end
        end

        function obj = set.MaximumQueueSize(obj, maxqsz)
            if ~isnumeric(maxqsz) || ~isscalar(maxqsz) || maxqsz <= 0 || ...
                    round(maxqsz) ~= maxqsz
                error("opentelemetry:sdk:trace:BatchSpanProcessor:InvalidMaxQueueSize", ...
                    "MaximumQueueSize must be a scalar positive integer.");
            end
            maxqsz = double(maxqsz);
            obj.Proxy.setMaximumQueueSize(maxqsz);
            obj.MaximumQueueSize = maxqsz;
        end

        function obj = set.ScheduledDelay(obj, delay)
            if ~isduration(delay) || ~isscalar(delay) || delay <= 0
                error("opentelemetry:sdk:trace:BatchSpanProcessor:InvalidScheduledDelay", ...
                    "ScheduledDelay must be a positive duration scalar.");
            end
            obj.Proxy.setScheduledDelay(milliseconds(delay));
            obj.ScheduledDelay = delay;
        end

        function obj = set.MaximumExportBatchSize(obj, maxbatch)
            if ~isnumeric(maxbatch) || ~isscalar(maxbatch) || maxbatch <= 0 || ...
                    round(maxbatch) ~= maxbatch
                error("opentelemetry:sdk:trace:BatchSpanProcessor:InvalidMaxExportBatchSize", ...
                    "MaximumExportBatchSize must be a scalar positive integer.");
            end
            maxbatch = double(maxbatch);
            obj.Proxy.setMaximumExportBatchSize(maxbatch);
            obj.MaximumExportBatchSize = maxbatch;
        end
    end
end
