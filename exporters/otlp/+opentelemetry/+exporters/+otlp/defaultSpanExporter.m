function dexp = defaultSpanExporter(varargin)
% Get the default span exporter depending on installation
%    EXP = OPENTELEMETRY.EXPORTERS.OTLP.DEFAULTSPANEXPORTER returns the 
%    default span exporter. OtlpHttpSpanExporter is the default if it is 
%    installed. Otherwise, OtlpGrpcSpanExporter is the default.
%
%    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER

% Copyright 2023 The MathWorks, Inc.

if exist("opentelemetry.exporters.otlp.OtlpHttpSpanExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpHttpSpanExporter(varargin{:});
else
    dexp = opentelemetry.exporters.otlp.OtlpGrpcSpanExporter(varargin{:});
end
