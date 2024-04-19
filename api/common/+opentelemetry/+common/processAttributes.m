function [attributekeys, attributevalues] = processAttributes(attrsin, onlydictionary)
% Perform error checking and type conversion for attributes
%    [PROCESSEDATTRNAMES, PROCESSEDATTRVALUES] = OPENTELEMETRY.COMMON.PROCESSATTRIBUTES(ATTRS)
%    performs error checking and type conversion on attributes ATTRS. ATTRS
%    is either a scalar dictionary, a scalar cell containing a dictionary, 
%    or a cell array containing name-value pairs. Returns valid attribute names
%    and values converted to types supported by the underlying OpenTelemetry-cpp
%    library. An attribute is invalid if its name is not a scalar string or
%    a char row, or if its value is not numeric, logical, string, or
%    cellstr.
%
%    [...] =  OPENTELEMETRY.COMMON.PROCESSATTRIBUTES(ATTRS, true) restrict
%    ATTRS to be a dictionary only. Name-value pairs are not allowed.

% Copyright 2024 The MathWorks, Inc.

if nargin < 2
    onlydictionary = false;
end

if isscalar(attrsin) && (isa(attrsin, "dictionary") || (iscell(attrsin) && ...
        isa(attrsin{1}, "dictionary")))
    % dictionary case
    if iscell(attrsin)
        attrsin = attrsin{1};
    end
    attributekeys = keys(attrsin);
    attributevalues = values(attrsin,"cell");
    % collapse one level of cells, as this may be due to
    % a behavior of dictionary.values
    if all(cellfun(@iscell, attributevalues))
        attributevalues = [attributevalues{:}];
    end
    % perform error checking and type conversion
    validattrs = false(size(attributekeys));
    for j = 1:length(attributekeys)
        [validattrs(j), attributekeys(j), attributevalues{j}] = ...
            processAttribute(attributekeys(j), attributevalues{j});
    end
    % remove the invalid attributes
    attributekeys = attributekeys(validattrs);
    attributevalues = attributevalues(validattrs);

elseif ~onlydictionary && iscell(attrsin) && isrow(attrsin)
    % NV pairs
    nin = length(attrsin);
    if rem(nin,2) ~= 0
        % Mismatched name-value pairs. Ignore all attributes.
        attributekeys = strings(1,0);
        attributevalues = cell(1,0);
        return
    end
    nattrs = nin / 2;
    attributekeys = strings(1,nattrs);
    attributevalues = cell(1,nattrs);
    validattrs = true(1,nattrs);
    currindex = 1;
    for i = 1:nattrs
        attrname = attrsin{currindex};
        attrvalue = attrsin{currindex+1};
        [validattrs(i), attributekeys(i), attributevalues{i}] = processAttribute(...
            attrname, attrvalue);
        currindex = currindex + 2;
    end
    % remove the invalid attributes
    attributekeys = attributekeys(validattrs);
    attributevalues = attributevalues(validattrs);
else
    % invalid attributes
    attributekeys = strings(1,0);
    attributevalues = cell(1,0);
    return
end
end

function [isvalid, attrname, attrval] = processAttribute(attrname, attrval)
% Local helper for an individual attribute

if ~(isStringScalar(attrname) || (ischar(attrname) && isrow(attrname)))
    isvalid = false;
    return
else
    attrname = string(attrname);
end
if isfloat(attrval)
    attrval = double(attrval);
elseif isinteger(attrval)
    if isa(attrval, "int8") || isa(attrval, "int16")
        attrval = int32(attrval);
    elseif isa(attrval, "uint8") || isa(attrval, "uint16")
        attrval = uint32(attrval);
    elseif isa(attrval, "uint64")
        attrval = int64(attrval);
    end
elseif (ischar(attrval) && isrow(attrval)) || iscellstr(attrval)
    attrval = string(attrval);
elseif ~(isstring(attrval) || islogical(attrval))
    isvalid = false;
    return
end
isvalid = true;
end