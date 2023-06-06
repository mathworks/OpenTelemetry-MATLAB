classdef SimpleSpanProcessor < opentelemetry.sdk.trace.SpanProcessor
% Simple span processor passes telemetry data to exporter as soon as they are generated.

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = SimpleSpanProcessor(spanexporter)
            % Simple span processor passes telemetry data to exporter as soon as they are generated.
            %    SSP = OPENTELEMETRY.SDK.TRACE.SIMPLESPANPROCESSOR creates 
            %    a simple span processor that uses an OTLP HTTP exporter, 
            %    which exports spans in OpenTelemetry Protocol (OTLP) format through HTTP.
            %
            %    SSP = OPENTELEMETRY.SDK.TRACE.SIMPLESPANPROCESSOR(EXP) specifies 
            %    the span exporter. Supported span exporters are OTLP HTTP 
            %    exporter and OTLP gRPC exporter.
            %                        
            %    See also OPENTELEMETRY.SDK.TRACE.BATCHSPANPROCESSOR, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER, 
            %    OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER  
            arguments
      	       spanexporter {mustBeA(spanexporter, "opentelemetry.sdk.trace.SpanExporter")} = ...
                   opentelemetry.exporters.otlp.OtlpHttpSpanExporter()
            end

            obj = obj@opentelemetry.sdk.trace.SpanProcessor(spanexporter, ...
                "libmexclass.opentelemetry.sdk.SimpleSpanProcessorProxy");
        end
    end
end
