function dexp = defaultSpanExporter(varargin)
% Get the default span exporter depending on installation
%    EXP = OPENTELEMETRY.EXPORTERS.OTLP.DEFAULTSPANEXPORTER returns the 
%    default span exporter. OtlpHttpSpanExporter is the default if it is 
%    installed. If not, OtlpGrpcSpanExporter is the default if it is 
%    installed. Otherwise, OtlpFileSpanExporter is the default.
%
%    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPFILESPANEXPORTER

% Copyright 2023-2024 The MathWorks, Inc.

if exist("opentelemetry.exporters.otlp.OtlpHttpSpanExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpHttpSpanExporter(varargin{:});
elseif exist("opentelemetry.exporters.otlp.OtlpGrpcSpanExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpGrpcSpanExporter(varargin{:});
else
    dexp = opentelemetry.exporters.otlp.OtlpFileSpanExporter(varargin{:});
end
