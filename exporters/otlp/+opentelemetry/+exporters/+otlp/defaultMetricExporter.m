function dexp = defaultMetricExporter(varargin)
% Get the default Metric exporter depending on installation
%    EXP = OPENTELEMETRY.EXPORTERS.OTLP.DEFAULTMETRICEXPORTER returns the 
%    default Metric exporter. OtlpHttpMetricExporter is the default if it is 
%    installed. If not, OtlpGrpcMetricExporter is the default if it is 
%    installed. Otherwise, OtlpFileMetricExporter is the default.
%
%    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMETRICEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCMETRICEXPORTER,
%    OPENTELEMETRY.EXPORTERS.OTLP.OTLPFILEMETRICEXPORTER

% Copyright 2023-2024 The MathWorks, Inc.

if exist("opentelemetry.exporters.otlp.OtlpHttpMetricExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(varargin{:});
elseif exist("opentelemetry.exporters.otlp.OtlpGrpcMetricExporter", "class")
    dexp = opentelemetry.exporters.otlp.OtlpGrpcMetricExporter(varargin{:});
else
    dexp = opentelemetry.exporters.otlp.OtlpFileMetricExporter(varargin{:});
end
