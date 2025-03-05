function [keys, values] = addDefaultResource(keys, values)
% Add default resource attributes
%    [KEYS, VALUES] = OPENTELEMETRY.SDK.COMMON.ADDDEFAULTRESOURCE(KEYS,
%    VALUES) appends default resource attribute names and values to the
%    input attribute names and values. The appended attribute names and
%    values are returned as output. Default resource attributes are
%    attributes that are always included in all telemetry data generated in
%    this package.

% Copyright 2025 The MathWorks, Inc.

% MATLAB version
v = string(version);

if isdeployed
    runtimename = "MATLAB Runtime";
else
    runtimename = "MATLAB";
end

keys = [keys; "process.runtime.name"; "process.runtime.version"];
values = [values; {runtimename}; {v}];
