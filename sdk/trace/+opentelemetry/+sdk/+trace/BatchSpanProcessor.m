classdef BatchSpanProcessor < opentelemetry.sdk.trace.SpanProcessor
% Batch span processor creates batches of spans and passes them to an exporter.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        MaximumQueueSize (1,1) double    % Maximum queue size. After queue size is reached, spans are dropped.
        ScheduledDelay (1,1) duration    % Time interval between span exports
        MaximumExportBatchSize (1,1) double   % Maximum batch size to export. 
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

            validnames = ["MaximumQueueSize", "ScheduledDelay", "MaximumExportBatchSize"];
            % set default values to negative
            qsize = -1;
            delaymillis = -1;
            batchsize = -1;
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "MaximumQueueSize")
                    if ~isnumeric(valuei) || ~isscalar(valuei) || valuei <= 0 || ...
                            round(valuei) ~= valuei
                        error("opentelemetry:sdk:trace:BatchSpanProcessor:InvalidMaxQueueSize", ...
                            "MaximumQueueSize must be a scalar positive integer.");
                    end
                    qsize = double(valuei);
                elseif strcmp(namei, "ScheduledDelay")
                    if ~isduration(valuei) || ~isscalar(valuei) || valuei <= 0
                        error("opentelemetry:sdk:trace:BatchSpanProcessor:InvalidScheduledDelay", ...
                            "ScheduledDelay must be a positive duration scalar.");
                    end
                    delay = valuei;
                    delaymillis = milliseconds(valuei);
                else   % "MaximumExportBatchSize" 
                    if ~isnumeric(valuei) || ~isscalar(valuei) || valuei <= 0 || ...
                            round(valuei) ~= valuei
                        error("opentelemetry:sdk:trace:BatchSpanProcessor:InvalidMaxExportBatchSize", ...
                            "MaximumExportBatchSize must be a scalar positive integer.");
                    end
                    batchsize = double(valuei);
                end
            end
            
            obj = obj@opentelemetry.sdk.trace.SpanProcessor(spanexporter, ...
                "libmexclass.opentelemetry.sdk.BatchSpanProcessorProxy", ...
                qsize, delaymillis, batchsize);

            % populate immutable properties
            if qsize < 0 || delaymillis < 0 || batchsize < 0
                [defaultqsize, defaultmillis, defaultbatchsize] = obj.Proxy.getDefaultOptionValues();
            end
            if qsize < 0  % not specified, use default value
                obj.MaximumQueueSize = defaultqsize;
            else
                obj.MaximumQueueSize = qsize;
            end
            if delaymillis < 0  % not specified, use default value
                obj.ScheduledDelay = milliseconds(defaultmillis);
            else
                obj.ScheduledDelay = delay;
            end
            if batchsize < 0  % not specified, use default value
                obj.MaximumExportBatchSize = defaultbatchsize;
            else
                obj.MaximumExportBatchSize = batchsize;
            end
        end
    end
end
