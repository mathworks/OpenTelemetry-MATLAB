function [keys, values] = addDefaultResource(keys, values)

% MATLAB version
v = string(version);

if isdeployed
    runtimename = "MATLAB Runtime";
else
    runtimename = "MATLAB";
end

keys = [keys; "process.runtime.name"; "process.runtime.version"];
values = [values; {runtimename}; {v}];
