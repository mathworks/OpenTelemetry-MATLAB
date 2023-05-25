classdef Context 
% Context class used to store context information including the current
% span and baggage

% Copyright 2023 The MathWorks, Inc.

    properties (Access={?opentelemetry.context.propagation.TextMapPropagator, ...
            ?opentelemetry.trace.Span, ?opentelemetry.trace.Tracer, ...
            ?opentelemetry.baggage.Baggage})
        Proxy
    end

    methods 
        function obj = Context(proxy)
            if nargin < 1
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.ContextProxy", ...
                    "ConstructorArguments", {});
            else
                obj.Proxy = proxy;
            end
        end

        function token = setCurrentContext(obj)
            tokenid = obj.Proxy.setCurrentContext();
            tokenproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TokenProxy", "ID", tokenid);
    	    token = opentelemetry.context.Token(tokenproxy);
        end
    end

end
