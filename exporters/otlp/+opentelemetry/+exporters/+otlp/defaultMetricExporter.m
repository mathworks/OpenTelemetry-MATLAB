function dexp = defaultMetricExporter
% Get the default Metric exporter depending on installation
%    EXP = OPENTELEMETRY.EXPORTERS.OTLP.DEFAULTMETRICEXPORTER returns the 
%    default Metric exporter. OtlpHttpMetricExporter is the default if it is 
%    installed. Otherwise, OtlpGrpcMetricExporter is the default.
%
%    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMetricEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCMetricEXPORTER

% Copyright 2023 The MathWorks, Inc.

if exist("opentelemetry.exporters.otlp.OtlpHttpMetricExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpHttpMetricExporter;
else
    dexp = opentelemetry.exporters.otlp.OtlpGrpcMetricExporter;
end
