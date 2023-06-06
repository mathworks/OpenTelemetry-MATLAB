classdef SpanProcessor < matlab.mixin.Heterogeneous
% Base class of span processors

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.trace.TracerProvider,...
		    ?opentelemetry.sdk.trace.BatchSpanProcessor})
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=immutable)
        SpanExporter  % Span exporter object responsible for exporting telemetry data to an OpenTelemetry Collector or a compatible backend.
    end

    methods (Access=protected)
        function obj = SpanProcessor(spanexporter, proxyname, varargin)
            % Base class constructor

            % Append SpanExporter proxy ID as the first input argument of 
            % proxy class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                "ConstructorArguments", [spanexporter.Proxy.ID varargin]);
            obj.SpanExporter = spanexporter;
        end
    end
end
