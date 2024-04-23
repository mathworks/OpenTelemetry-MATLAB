classdef LogRecordProcessor < matlab.mixin.Heterogeneous
% Base class of log record processors

% Copyright 2024 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.logs.LoggerProvider,...
		    ?opentelemetry.sdk.logs.BatchLogRecordProcessor})
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=immutable)
        LogRecordExporter  % Log record exporter object responsible for exporting telemetry data to an OpenTelemetry Collector or a compatible backend.
    end

    methods (Access=protected)
        function obj = LogRecordProcessor(exporter, proxyname, varargin)
            % Base class constructor

            % Append SpanExporter proxy ID as the first input argument of 
            % proxy class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                "ConstructorArguments", [exporter.Proxy.ID varargin]);
            obj.LogRecordExporter = exporter;
        end
    end
end
