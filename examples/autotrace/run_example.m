function yf = run_example
% Use AutoTrace to automatically instrument an example to produce a trace.

% Copyright 2024 The MathWorks, Inc.

% configure tracer provider
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
tp = opentelemetry.sdk.trace.TracerProvider(Resource=resource);
setTracerProvider(tp);

% create AutoTrace object
at = opentelemetry.autoinstrument.AutoTrace(@autotrace_example, ...
    TracerName="autotrace_example");

% run the example
yf = beginTrace(at);