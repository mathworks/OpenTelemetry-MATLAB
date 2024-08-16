classdef SpanExporter
% Base class of span exporters

% Copyright 2023-2024 The MathWorks, Inc.

    properties (Hidden, GetAccess={?opentelemetry.sdk.trace.SpanProcessor, ...
            ?opentelemetry.exporters.otlp.OtlpHttpSpanExporter, ...
            ?opentelemetry.exporters.otlp.OtlpGrpcSpanExporter, ...
            ?opentelemetry.exporters.otlp.OtlpFileSpanExporter})
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = SpanExporter(proxyname, varargin)
            % Base class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                "ConstructorArguments", varargin);
        end
    end
end
