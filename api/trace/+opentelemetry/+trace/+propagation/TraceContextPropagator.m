classdef TraceContextPropagator < opentelemetry.context.propagation.TextMapPropagator
% Propagator for injecting and extracting trace context from HTTP header

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = TraceContextPropagator()
            % Propagator for injecting and extracting trace context from HTTP headers.
            %    PROP = OPENTELEMETRY.TRACE.PROPAGATION.TRACECONTEXTPROPAGATOR 
            %    creates a propagator that can be used for injecting or
            %    extracting trace context from HTTP headers.
            %
            %    See also
            %    OPENTELEMETRY.BAGGAGE.PROPAGATION.BAGGAGEPROPAGATOR
            proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TraceContextPropagatorProxy", ...
                "ConstructorArguments", {});
            obj = obj@opentelemetry.context.propagation.TextMapPropagator(proxy);
        end
    end

end
