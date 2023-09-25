classdef MetricExporter
% Base class of metric exporters

% Copyright 2023 The MathWorks, Inc.

    properties (Access=?opentelemetry.sdk.metrics.PeriodicExportingMetricReader)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = MetricExporter(proxyname, varargin)
            % Base class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                "ConstructorArguments", varargin);
        end

        function varargout = getDefaultOptionValues(obj)
            [varargout{1:nargout}] = obj.Proxy.getDefaultOptionValues();
        end
    end
end
