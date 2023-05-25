classdef CompositePropagator < opentelemetry.context.propagation.TextMapPropagator
% Composite propagator composed of multiple propagators

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = CompositePropagator(propagator)
            arguments (Repeating)
                propagator (1,1) {mustBeA(propagator, ...
                    ["opentelemetry.trace.propagation.TraceContextPropagator", ...
                    "opentelemetry.baggage.propagation.BaggagePropagator"])}
            end
            ids = cellfun(@(p)p.Proxy.ID, propagator);
            proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.CompositePropagatorProxy", ...
                "ConstructorArguments", {ids});
            obj = obj@opentelemetry.context.propagation.TextMapPropagator(proxy);
        end
    end

end