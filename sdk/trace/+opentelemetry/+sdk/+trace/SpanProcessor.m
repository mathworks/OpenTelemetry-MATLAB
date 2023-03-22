classdef SpanProcessor
% Base class of span processors

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.trace.TracerProvider,...
		    ?opentelemetry.sdk.trace.BatchSpanProcessor})
        Proxy
    end

    properties (SetAccess=immutable)
        SpanExporter
    end

    methods (Access=protected)
        function obj = SpanProcessor(spanexporter, proxyname, varargin)
            % Append SpanExporter proxy ID as the first input argument of 
            % proxy class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                "ConstructorArguments", [spanexporter.Proxy.ID varargin]);
            obj.SpanExporter = spanexporter;
        end
    end
end
