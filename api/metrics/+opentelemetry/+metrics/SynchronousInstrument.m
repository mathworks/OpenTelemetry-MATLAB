classdef SynchronousInstrument < handle
    % Base class inherited by all synchronous instruments

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name        (1,1) string     % Instrument name
        Description (1,1) string     % Description of instrument
        Unit        (1,1) string     % Measurement unit
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
            import opentelemetry.common.processAttributes
            % input value must be a numerical real scalar
            if isnumeric(value) && isscalar(value) && isreal(value)
                if nargin == 2
                    obj.Proxy.processValue(value);
                else
                    % attributes
                    [attrkeys, attrvalues] = processAttributes(varargin);
                    obj.Proxy.processValue(value, attrkeys, attrvalues);
                end
            end
        end
    end
end
