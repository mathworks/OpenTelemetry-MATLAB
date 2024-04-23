classdef SimpleLogRecordProcessor < opentelemetry.sdk.logs.LogRecordProcessor
% Simple log record processor passes telemetry data to exporter as soon as they are generated.

% Copyright 2024 The MathWorks, Inc.

    methods
        function obj = SimpleLogRecordProcessor(exporter)
            % Simple log record processor passes telemetry data to exporter as soon as they are generated.
            %    SLP = OPENTELEMETRY.SDK.LOGS.SIMPLELOGRECORDPROCESSOR creates 
            %    a simple log record processor that uses an OTLP HTTP exporter, 
            %    which exports log records in OpenTelemetry Protocol (OTLP) format through HTTP.
            %
            %    SLP = OPENTELEMETRY.SDK.LOGS.SIMPLELOGRECORDPROCESSOR(EXP) specifies 
            %    the log record exporter. Supported log record exporters are OTLP HTTP 
            %    exporter and OTLP gRPC exporter.
            %                        
            %    See also OPENTELEMETRY.SDK.LOGS.BATCHLOGRECORDPROCESSOR, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPLOGRECORDEXPORTER, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCLOGRECORDEXPORTER, 
            %    OPENTELEMETRY.SDK.LOGS.LOGGERPROVIDER  
            arguments
      	       exporter {mustBeA(exporter, "opentelemetry.sdk.logs.LogRecordExporter")} = ...
                   opentelemetry.exporters.otlp.defaultLogRecordExporter()
            end

            obj = obj@opentelemetry.sdk.logs.LogRecordProcessor(exporter, ...
                "libmexclass.opentelemetry.sdk.SimpleLogRecordProcessorProxy");
        end
    end
end
