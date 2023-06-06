classdef TextMapPropagator
% Base propagator class for injecting and extracting context data

% Copyright 2023 The MathWorks, Inc.

    properties (Access=?opentelemetry.context.propagation.CompositePropagator)
        Proxy    % Proxy object to interface C++ code
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
            % EXTRACT  Extract HTTP header from carrier into a context.
            %    NEWCTXT = EXTRACT(PROP, C, CTXT) extracts HTTP header
            %    stored in carrier C into context CTXT, and returns a new
            %    context NEWCTXT.
            %
            %    See also INJECT, OPENTELEMETRY.CONTEXT.CONTEXT,
            %    OPENTELEMETRY.CONTEXT.PROPAGATION.TEXTMAPCARRIER
            if nargin < 3
                context = opentelemetry.context.getCurrentContext();
            end
            newcontextid = obj.Proxy.extract(carrier.Proxy.ID, context.Proxy.ID);
            newcontextproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ContextProxy", "ID", newcontextid);
    	    newcontext = opentelemetry.context.Context(newcontextproxy);
        end

        function newcarrier = inject(obj, carrier, context)
            % INJECT  Inject HTTP header from a context into a carrier.
            %    C = INJECT(PROP, C, CTXT) injects HTTP header in context 
            %    CTXT into carrier C.
            %
            %    See also EXTRACT, OPENTELEMETRY.CONTEXT.CONTEXT,
            %    OPENTELEMETRY.CONTEXT.PROPAGATION.TEXTMAPCARRIER
            if nargin < 3
                context = opentelemetry.context.getCurrentContext();
            end
            newcarrierid = obj.Proxy.inject(carrier.Proxy.ID, context.Proxy.ID);
            newcarrierproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TextMapCarrierProxy", "ID", newcarrierid);
    	    newcarrier = opentelemetry.context.propagation.TextMapCarrier(newcarrierproxy);
        end

        function setTextMapPropagator(obj)
            % SETTEXTMAPPROPAGATOR Set propagator as the global instance.
            %    SETTEXTMAPPROPAGATOR(PROP) sets the propagator PROP as the
            %    global instance.
            %
            %    See also
            %    OPENTELEMETRY.CONTEXT.PROPAGATION.PROPAGATOR.GETTEXTMAPPROPAGATOR
            obj.Proxy.setTextMapPropagator();
        end
    end

end
