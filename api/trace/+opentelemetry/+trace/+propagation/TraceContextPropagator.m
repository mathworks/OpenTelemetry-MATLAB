classdef TraceContextPropagator < opentelemetry.context.propagation.TextMapPropagator
% Propagator for injecting and extracting trace context from HTTP header

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = TraceContextPropagator()
            proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TraceContextPropagatorProxy", ...
                "ConstructorArguments", {});
            obj = obj@opentelemetry.context.propagation.TextMapPropagator(proxy);
        end
    end

end
