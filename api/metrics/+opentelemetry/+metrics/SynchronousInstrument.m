classdef SynchronousInstrument < handle
    % Base class inherited by all synchronous instruments

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name        (1,1) string  
        Description (1,1) string   
        Unit        (1,1) string   
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = SynchronousInstrument(proxy, name, description, unit)
            obj.Proxy = proxy;
            obj.Name = name;
            obj.Description = description;
            obj.Unit = unit;
        end

        function processValue(obj, value, varargin)
            % input value must be a numerical real scalar
            if isnumeric(value) && isscalar(value) && isreal(value)
                if nargin == 2
                    obj.Proxy.processValue(value);
                elseif isa(varargin{1}, "dictionary")
                    attrkeys = keys(varargin{1});
                    attrvals = values(varargin{1},"cell");
                    if all(cellfun(@iscell, attrvals))
                        attrvals = [attrvals{:}];
                    end
                    obj.Proxy.processValue(value, attrkeys, attrvals);
                else
                    attrkeys = [varargin{1:2:length(varargin)}]';
                    attrvals = [varargin(2:2:length(varargin))]';
                    obj.Proxy.processValue(value, attrkeys, attrvals);
                end
            end
        end
    end
end