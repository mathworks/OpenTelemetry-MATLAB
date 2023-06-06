function tracer = getTracer(trname, varargin)
% Create a tracer from the global tracer provider instance 
%    TR = OPENTELEMETRY.TRACE.GETTRACER(NAME) returns a tracer with the
%    specified name created from the global tracer provider instance.
%
%    TR = OPENTELEMETRY.TRACE.GETTRACER(NAME, VERSION, SCHEMA) also
%    specifies the tracer version and the URL that documents the schema
%    of the generated spans.
%
%    See also OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER,
%    OPENTELEMETRY.TRACE.TRACER,
%    OPENTELEMETRY.TRACE.PROVIDER.SETTRACERPROVIDER

% Copyright 2023 The MathWorks, Inc.

provider = opentelemetry.trace.Provider.getTracerProvider();
tracer = getTracer(provider, trname, varargin{:});
