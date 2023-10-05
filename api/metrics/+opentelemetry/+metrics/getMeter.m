function meter = getMeter(mname, varargin)
% Create a meter from the global meter provider instance 
%    M = OPENTELEMETRY.TRACE.GETMETER(NAME) returns a meter with the
%    specified name created from the global meter provider instance.
%
%    M = OPENTELEMETRY.METRICS.GETMETER(NAME, VERSION, SCHEMA) also
%    specifies the meter version and the URL that documents the schema
%    of the generated metrics.
%
%    See also OPENTELEMETRY.SDK.METRICS.METERPROVIDER,
%    OPENTELEMETRY.METRICS.METER,
%    OPENTELEMETRY.METRICS.PROVIDER.SETMETERPROVIDER

% Copyright 2023 The MathWorks, Inc.

provider = opentelemetry.metrics.Provider.getMeterProvider();
meter = getMeter(provider, mname, varargin{:});
