classdef BaggagePropagator < opentelemetry.context.propagation.TextMapPropagator
% Propagator for injecting and extracting baggage from HTTP header

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = BaggagePropagator()
            % Propagator for injecting and extracting baggage from HTTP header
            %    PROP = OPENTELEMETRY.BAGGAGE.PROPAGATION.BAGGAGEPROPAGATOR
            %    creates a baggage propagator.
            %
            %    See also
            %    OPENTELEMETRY.TRACE.PROPAGATION.TRACECONTEXTPROPAGATOR
            proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.BaggagePropagatorProxy", ...
                "ConstructorArguments", {});
            obj = obj@opentelemetry.context.propagation.TextMapPropagator(proxy);
        end
    end

end