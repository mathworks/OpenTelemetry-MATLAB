function newcontext = extractContext(carrier)
% Extract HTTP header from TextMapCarrier
%    NEWCTXT = OPENTELEMETRY.CONTEXT.PROPAGATION.EXTRACTCONTEXT(C) uses the 
%    global instance of text map propagator to extract HTTP header from 
%    carrier C into the current context and returns a new context. 
%
%    See also OPENTELEMETRY.CONTEXT.PROPAGATION.INJECTCONTEXT

% Copyright 2023 The MathWorks, Inc.

propagator = opentelemetry.context.propagation.Propagator.getTextMapPropagator();
context = opentelemetry.context.getCurrentContext();
newcontext = propagator.extract(carrier, context);