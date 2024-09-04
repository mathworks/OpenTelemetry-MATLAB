classdef BatchLogRecordProcessor < opentelemetry.sdk.logs.LogRecordProcessor
% Batch log record processor creates batches of log records and passes them to an exporter.

% Copyright 2024 The MathWorks, Inc.

    properties
        MaximumQueueSize (1,1) double = 2048       % Maximum queue size. After queue size is reached, log records are dropped.
        ScheduledDelay (1,1) duration = seconds(5) % Time interval between exports
        MaximumExportBatchSize (1,1) double = 512  % Maximum batch size to export. 
    end

    methods
        function obj = BatchLogRecordProcessor(varargin)
            % Batch log record processor creates batches of log records and passes them to an exporter.
            %    BLP = OPENTELEMETRY.SDK.LOGS.BATCHLOGRECORDPROCESSOR creates a 
            %    batch log record processor that uses an OTLP HTTP exporter, which 
            %    exports log records in OpenTelemetry Protocol (OTLP) format through HTTP.
            %
            %    BLP = OPENTELEMETRY.SDK.LOGS.BATCHLOGRECORDPROCESSOR(EXP) specifies 
            %    the log record exporter. Supported log record exporters are OTLP HTTP 
            %    exporter and OTLP gRPC exporter.
            %    
            %    BLP = OPENTELEMETRY.SDK.LOGS.BATCHLOGRECORDPROCESSOR(..., PARAM1, 
            %    VALUE1, PARAM2, VALUE2, ...) specifies optional parameter 
            %    name/value pairs. Parameters are:
            %       "MaximumQueueSize"  - Maximum queue size. After queue
            %                             size is reached, log records are dropped. 
            %                             Default value is 2048.
            %       "ScheduledDelay"    - Time interval between exports. 
            %                             Default interval is 5 seconds.
            %       "MaximumExportBatchSize"  - Maximum batch size to export.
            %                                   Default size is 512.
            %                        
            %    See also OPENTELEMETRY.SDK.LOGS.SIMPLELOGRECORDPROCESSOR, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPLOGRECORDEXPORTER, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCLOGRECORDEXPORTER, 
            %    OPENTELEMETRY.SDK.LOGS.LOGGERPROVIDER  

            if nargin == 0 || ~isa(varargin{1}, "opentelemetry.sdk.logs.LogRecordExporter")
                exporter = opentelemetry.exporters.otlp.defaultLogRecordExporter;
            else   % isa(varargin{1}, "opentelemetry.sdk.logs.LogRecordExporter")
                exporter = varargin{1};
                varargin(1) = [];
            end

            obj = obj@opentelemetry.sdk.logs.LogRecordProcessor(exporter, ...
                "libmexclass.opentelemetry.sdk.BatchLogRecordProcessorProxy");

            obj = obj.processOptions(varargin{:});
        end

        function obj = set.MaximumQueueSize(obj, maxqsz)
            if ~isnumeric(maxqsz) || ~isscalar(maxqsz) || maxqsz <= 0 || ...
                    round(maxqsz) ~= maxqsz
                error("opentelemetry:sdk:logs:BatchLogRecordProcessor:InvalidMaxQueueSize", ...
                    "MaximumQueueSize must be a scalar positive integer.");
            end
            maxqsz = double(maxqsz);
            obj.Proxy.setMaximumQueueSize(maxqsz);
            obj.MaximumQueueSize = maxqsz;
        end

        function obj = set.ScheduledDelay(obj, delay)
            if ~isduration(delay) || ~isscalar(delay) || delay <= 0
                error("opentelemetry:sdk:logs:BatchLogRecordProcessor:InvalidScheduledDelay", ...
                    "ScheduledDelay must be a positive duration scalar.");
            end
            obj.Proxy.setScheduledDelay(milliseconds(delay));
            obj.ScheduledDelay = delay;
        end

        function obj = set.MaximumExportBatchSize(obj, maxbatch)
            if ~isnumeric(maxbatch) || ~isscalar(maxbatch) || maxbatch <= 0 || ...
                    round(maxbatch) ~= maxbatch
                error("opentelemetry:sdk:logs:BatchLogRecordProcessor:InvalidMaxExportBatchSize", ...
                    "MaximumExportBatchSize must be a scalar positive integer.");
            end
            maxbatch = double(maxbatch);
            obj.Proxy.setMaximumExportBatchSize(maxbatch);
            obj.MaximumExportBatchSize = maxbatch;
        end
    end

    methods(Access=private)
        function obj = processOptions(obj, optionnames, optionvalues)
            arguments
      	       obj
            end
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end
            validnames = ["MaximumQueueSize", "ScheduledDelay", "MaximumExportBatchSize"];
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                obj.(namei) = valuei;
            end
        end
    end
end
