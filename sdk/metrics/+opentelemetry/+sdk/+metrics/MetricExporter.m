classdef MetricExporter
% Base class of metric exporters

% Copyright 2023 The MathWorks, Inc.

    properties
	PreferredAggregationTemporality (1,1) string = "cumulative"   % Preferred Aggregation Temporality
    end

    properties (Access={?opentelemetry.sdk.metrics.PeriodicExportingMetricReader, ...
            ?opentelemetry.exporters.otlp.OtlpHttpMetricExporter, ...
            ?opentelemetry.exporters.otlp.OtlpGrpcMetricExporter})
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = MetricExporter(proxyname, varargin)
            % Base class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                "ConstructorArguments", varargin);
        end
    end

    methods
	    function obj = set.PreferredAggregationTemporality(obj, temporality)
            temporality = validatestring(temporality, ["cumulative", "delta"]);
            obj.Proxy.setTemporality(temporality); %#ok<MCSUP>
            obj.PreferredAggregationTemporality = temporality;
        end

    end
end
