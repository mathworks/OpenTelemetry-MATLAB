classdef Context 
% Propagation mechanism used to carry context data across functions and
% external interfaces.

% Copyright 2023-2024 The MathWorks, Inc.

    properties (Access={?opentelemetry.context.propagation.TextMapPropagator, ...
            ?opentelemetry.trace.Span, ?opentelemetry.trace.SpanContext, ...
            ?opentelemetry.trace.Tracer, ?opentelemetry.logs.Logger, ...
            ?opentelemetry.baggage.Baggage})
        Proxy   % Proxy object to interface C++ code
    end

    methods 
        function obj = Context(proxy)
            % Propagation mechanism used to carry context data across functions and external interfaces.
            %    CTXT = OPENTELEMETRY.CONTEXT.CONTEXT creates an empty
            %    context object.
            if nargin < 1
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.ContextProxy", ...
                    "ConstructorArguments", {});
            else
                obj.Proxy = proxy;
            end
        end

        function token = setCurrentContext(obj)
            % SETCURRENTCONTEXT Set context to be current context.
            %    TOKEN = SETCURRENTCONTEXT(CTXT) sets context to be current
            %    context and returns a token object which determines the duration 
            %    when CTXT is current. When TOKEN is deleted, CTXT will no longer be current. 
            %
            %    See also OPENTELEMETRY.CONTEXT.TOKEN
            tokenid = obj.Proxy.setCurrentContext();
            tokenproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TokenProxy", "ID", tokenid);
    	    token = opentelemetry.context.Token(tokenproxy);
        end
    end

end
