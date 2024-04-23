function dexp = defaultLogRecordExporter(varargin)
% Get the default log record exporter depending on installation
%    EXP = OPENTELEMETRY.EXPORTERS.OTLP.DEFAULTSPANEXPORTER returns the 
%    default log record exporter. OtlpHttpLogRecordExporter is the default if it is 
%    installed. Otherwise, OtlpGrpcLogRecordExporter is the default.
%
%    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPLOGRECORDEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCLOGRECORDEXPORTER

% Copyright 2024 The MathWorks, Inc.

if exist("opentelemetry.exporters.otlp.OtlpHttpLogRecordExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpHttpLogRecordExporter(varargin{:});
else
    dexp = opentelemetry.exporters.otlp.OtlpGrpcLogRecordExporter(varargin{:});
end
