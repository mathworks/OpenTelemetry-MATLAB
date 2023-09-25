classdef PeriodicExportingMetricReader < matlab.mixin.Heterogeneous
% Base class of metric reader

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess=?opentelemetry.sdk.metrics.MeterProvider)
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=immutable)
        MetircExporter  % Metric exporter object responsible for exporting telemetry data to an OpenTelemetry Collector or a compatible backend.
        Interval (1,1) double    % Maximum queue size. After queue size is reached, spans are dropped.
        Timeout (1,1) double
    end

    methods (Access=protected)
        function obj = PeriodicExportingMetricReader(metricexporter, optionnames, optionvalues)
           
            arguments
      	       metricexporter {mustBeA(metricexporter, "opentelemetry.sdk.metrics.MetricExporter")} = ...
                   opentelemetry.exporters.otlp.defaultMetricExporter()
            end
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["Interval", "Timeout"];
            % set default values 
            intervalmills = 60;
            timeoutmills = 30;
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Interval")
                    if ~isnumeric(valuei) || ~isscalar(valuei) || valuei <= 0 || ...
                            round(valuei) ~= valuei
                        error("opentelemetry:sdk:metrics::PeriodicExportingMetricReader::InvalidInterval", ...
                            "Interval must be a scalar positive integer.");
                    end
                    intervalmills = double(valuei);
                elseif strcmp(namei, "Timeout")
                    if ~isduration(valuei) || ~isscalar(valuei) || valuei <= 0
                        error("opentelemetry:sdk:metrics:PeriodicExportingMetricReader:InvalidTimeout", ...
                            "Timeout must be a positive duration scalar.");
                    end
                    timeoutmillis = milliseconds(valuei);
            end
            
            obj.MetricExporter = metricexporter;
            obj.Interval = intervalmills;
            obj.Timeout = timeoutmillis;
            obj.Proxy = libmexclass.proxy.Proxy("Name", "libmexclass.opentelemetry.sdk.PeriodicExportingMetricReaderProxy" , ...
                                                "ConstructorArguments", [metricexporter.Proxy.ID, Interval, Timeout]);

        end
    end
end
