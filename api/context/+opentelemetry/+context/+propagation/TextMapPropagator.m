classdef TextMapPropagator
% Base propagator class for injecting and extracting context data

% Copyright 2023 The MathWorks, Inc.

    properties (Access=?opentelemetry.context.propagation.CompositePropagator)
        Proxy
    end

    methods (Access={?opentelemetry.context.propagation.Propagator, ...
            ?opentelemetry.trace.propagation.TraceContextPropagator, ...
            ?opentelemetry.baggage.propagation.BaggagePropagator, ...
            ?opentelemetry.context.propagation.CompositePropagator})
        function obj = TextMapPropagator(proxy)
            if nargin < 1
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.TextMapPropagatorProxy", ...
                    "ConstructorArguments", {});
            else
                obj.Proxy = proxy;
            end
        end
    end
    
    methods
        function newcontext = extract(obj, carrier, context)
            if nargin < 3
                context = opentelemetry.context.getCurrentContext();
            end
            newcontextid = obj.Proxy.extract(carrier.Proxy.ID, context.Proxy.ID);
            newcontextproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ContextProxy", "ID", newcontextid);
    	    newcontext = opentelemetry.context.Context(newcontextproxy);
        end

        function newcarrier = inject(obj, carrier, context)
            if nargin < 3
                context = opentelemetry.context.getCurrentContext();
            end
            newcarrierid = obj.Proxy.inject(carrier.Proxy.ID, context.Proxy.ID);
            newcarrierproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TextMapCarrierProxy", "ID", newcarrierid);
    	    newcarrier = opentelemetry.context.propagation.TextMapCarrier(newcarrierproxy);
        end

        function setTextMapPropagator(obj)
            obj.Proxy.setTextMapPropagator();
        end
    end

end
