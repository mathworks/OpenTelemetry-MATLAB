classdef LogRecordExporter
% Base class of log record exporters

% Copyright 2024 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.logs.LogRecordProcessor, ...
            ?opentelemetry.exporters.otlp.OtlpHttpLogRecordExporter, ...
            ?opentelemetry.exporters.otlp.OtlpGrpcLogRecordExporter, ...
            ?opentelemetry.exporters.otlp.OtlpFileLogRecordExporter})
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = LogRecordExporter(proxyname, varargin)
            % Base class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...xx
                "ConstructorArguments", varargin);
        end
    end
end
