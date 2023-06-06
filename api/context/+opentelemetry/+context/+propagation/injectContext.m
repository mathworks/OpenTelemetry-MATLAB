function carrier = injectContext(carrier)
% Inject HTTP header into a TextMapCarrier
%    C = OPENTELEMETRY.CONTEXT.PROPAGATION.INJECTCONTEXT(C) uses the 
%    global instance of text map propagator to inject HTTP header from 
%    the current context into carrier C. 
%
%    See also OPENTELEMETRY.CONTEXT.PROPAGATION.EXTRACTCONTEXT

% Copyright 2023 The MathWorks, Inc.

if nargin < 1
    carrier = opentelemetry.context.propagation.TextMapCarrier();
end
propagator = opentelemetry.context.propagation.Propagator.getTextMapPropagator();
context = opentelemetry.context.getCurrentContext();
carrier = propagator.inject(carrier, context);