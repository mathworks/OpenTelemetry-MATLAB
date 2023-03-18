classdef SimpleSpanProcessor
% Simple span processor passes telemetry data to exporter as soon as they are generated.

% Copyright 2023 The MathWorks, Inc.

    properties (Access=?opentelemetry.sdk.trace.TracerProvider)
        Proxy
    end

    methods
        function obj = SimpleSpanProcessor()
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.SimpleSpanProcessorProxy", ...
                "ConstructorArguments", {});
        end
    end
end
