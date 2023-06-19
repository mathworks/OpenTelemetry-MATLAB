function dexp = defaultSpanExporter
% Get the default span exporter depending on installation
%    EXP = OPENTELEMETRY.EXPORTERS.OTLP.DEFAULTSPANEXPORTER returns the 
%    default span exporter. OtlpHttpSpanExporter is the default if it is 
%    installed. Otherwise, OtlpGrpcSpanExporter is the default.
%
%    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER

% Copyright 2023 The MathWorks, Inc.

if exist("opentelemetry.exporters.otlp.OtlpHttpSpanExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpHttpSpanExporter;
else
    dexp = opentelemetry.exporters.otlp.OtlpGrpcSpanExporter;
end
