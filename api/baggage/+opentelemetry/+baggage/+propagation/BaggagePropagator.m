classdef BaggagePropagator < opentelemetry.context.propagation.TextMapPropagator
% Propagator for injecting and extracting baggage from HTTP header

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = BaggagePropagator()
            proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.BaggagePropagatorProxy", ...
                "ConstructorArguments", {});
            obj = obj@opentelemetry.context.propagation.TextMapPropagator(proxy);
        end
    end

end