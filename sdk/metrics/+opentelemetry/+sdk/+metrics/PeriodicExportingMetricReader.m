classdef PeriodicExportingMetricReader < matlab.mixin.Heterogeneous
% Periodic exporting metric reader passes collected metrics to an exporter
% periodically at a fixed time interval.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess=?opentelemetry.sdk.metrics.MeterProvider)
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=immutable)
        MetricExporter  % Metric exporter object responsible for exporting telemetry data to an OpenTelemetry Collector or a compatible backend.
    end

    properties
        Interval (1,1) duration = minutes(1)  % Time interval between exports
        Timeout (1,1) duration = seconds(30)  % Maximum time before export is timed out and gets aborted
    end

    methods
        function obj = PeriodicExportingMetricReader(metricexporter, optionnames, optionvalues)
            % Periodic exporting metric reader passes collected metrics to
            % an exporter periodically at a fixed time interval.
            %    R = OPENTELEMETRY.SDK.METRICS.PERIODICEXPORTINGMETRICREADER
            %    creates a periodic exporting metric reader that exports 
            %    every minute using an OTLP HTTP exporter, which exports in 
            %    OpenTelemetry Protocol (OTLP) format through HTTP.
            %
            %    R = OPENTELEMETRY.SDK.METRICS.PERIODICEXPORTINGMETRICREADER(EXP)
            %    specifies the metric exporter. Supported metric exporters
            %    are OTLP HTTP exporter and OTLP gRPC exporter.
            %
            %    R = OPENTELEMETRY.SDK.METRICS.PERIODICEXPORTINGMETRICREADER(
            %    EXP, PARAM1, VALUE1, PARAM2, VALUE2, ...) specifies
            %    optional parameter name/value pairs. Parameters are:
            %       "Interval" - Time interval between exports specified as
            %                    a duration. Default is 1 minute.
            %       "Timeout"  - Maximum time before export is timed out
            %                    and gets aborted, specified as a duration.  
            %                    Default is 30 seconds.
            %
            %    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMETRICEXPORTER,
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCMETRICEXPORTER, 
            %    OPENTELEMETRY.SDK.METRICS.METERPROVIDER
            arguments
      	       metricexporter {mustBeA(metricexporter, "opentelemetry.sdk.metrics.MetricExporter")} = ...
                   opentelemetry.exporters.otlp.defaultMetricExporter()
            end
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            obj.Proxy = libmexclass.proxy.Proxy("Name", "libmexclass.opentelemetry.sdk.PeriodicExportingMetricReaderProxy" , ...
                "ConstructorArguments", {metricexporter.Proxy.ID});
            obj.MetricExporter = metricexporter;

            validnames = ["Interval", "Timeout"];
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                obj.(namei) = valuei;
            end
        end

        function obj = set.Interval(obj, interval)
            if ~isduration(interval) || ~isscalar(interval) || interval <= 0 || ...
                    round(interval) ~= interval
                error("opentelemetry:sdk:metrics:PeriodicExportingMetricReader:InvalidInterval", ...
                    "Interval must be a positive duration integer.");
            end
            obj.Proxy.setInterval(milliseconds(interval)); %#ok<MCSUP>
            obj.Interval = interval;
        end

        function obj = set.Timeout(obj, timeout)
            if ~isduration(timeout) || ~isscalar(timeout) || timeout <= 0
                error("opentelemetry:sdk:metrics:PeriodicExportingMetricReader:InvalidTimeout", ...
                    "Timeout must be a positive duration scalar.");
            end
            obj.Proxy.setTimeout(milliseconds(timeout)); %#ok<MCSUP>
            obj.Timeout = timeout;
        end
    end
end
