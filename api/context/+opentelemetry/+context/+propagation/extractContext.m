function newcontext = extractContext(carrier)
% Extract context data from TextMapCarrier

% Copyright 2023 The MathWorks, Inc.

propagator = opentelemetry.context.propagation.Propagator.getTextMapPropagator();
context = opentelemetry.context.getCurrentContext();
newcontext = propagator.extract(carrier, context);