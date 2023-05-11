function carrier = injectContext(carrier)
% Inject context data into a TextMapCarrier

% Copyright 2023 The MathWorks, Inc.

if nargin < 1
    carrier = opentelemetry.context.propagation.TextMapCarrier();
end
propagator = opentelemetry.context.propagation.Propagator.getTextMapPropagator();
context = opentelemetry.context.getCurrentContext();
carrier = propagator.inject(carrier, context);