function str = mustBeScalarString(str)
% Convert into a scalar string
%    STR = OPENTELEMETRY.UTILS.MUSTBESCALARSTRING(X) converts X into a
%    scalar string. If X is an array, only the first element will be kept.
%    If X is empty, an empty string is returned. If X cannot be converted
%    into string, an error will be thrown.

% Copyright 2023 The MathWorks, Inc.

str = string(str);
if isempty(str)
    str = "";
else
    str = str(1);
end