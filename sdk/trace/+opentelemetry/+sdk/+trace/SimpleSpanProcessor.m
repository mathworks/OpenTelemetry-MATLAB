classdef SimpleSpanProcessor < opentelemetry.sdk.trace.SpanProcessor
% Simple span processor passes telemetry data to exporter as soon as they are generated.

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = SimpleSpanProcessor(spanexporter)
            arguments
      	       spanexporter {mustBeA(spanexporter, "opentelemetry.sdk.trace.SpanExporter")} = ...
                   opentelemetry.exporters.otlp.OtlpHttpSpanExporter()
            end

            obj = obj@opentelemetry.sdk.trace.SpanProcessor(spanexporter, ...
                "libmexclass.opentelemetry.sdk.SimpleSpanProcessorProxy");
        end
    end
end
