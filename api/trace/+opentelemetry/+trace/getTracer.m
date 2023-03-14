function tracer = getTracer(trname, varargin)
% Get a tracer from the global tracer provider instance 

% Copyright 2023 The MathWorks, Inc.

provider = opentelemetry.trace.Provider.getTracerProvider();
tracer = getTracer(provider, trname, varargin{:});
