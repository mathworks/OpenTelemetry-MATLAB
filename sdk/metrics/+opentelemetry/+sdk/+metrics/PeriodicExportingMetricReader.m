classdef PeriodicExportingMetricReader < matlab.mixin.Heterogeneous
% Base class of metric reader

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess=?opentelemetry.sdk.metrics.MeterProvider)
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=immutable)
        MetricExporter  % Metric exporter object responsible for exporting telemetry data to an OpenTelemetry Collector or a compatible backend.
    end

    properties
        Interval (1,1) duration = minutes(1)  
        Timeout (1,1) duration = seconds(30)
    end

    methods %(Access=?opentelemetry.sdk.metrics.MeterProvider)
        function obj = PeriodicExportingMetricReader(metricexporter, optionnames, optionvalues)
           
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
