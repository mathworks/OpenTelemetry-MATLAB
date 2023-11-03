classdef UpDownCounter < opentelemetry.metrics.SynchronousInstrument
    % UpDownCounter is an instrument that adds or reduce values.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access={?opentelemetry.metrics.Meter})
        function obj = UpDownCounter(proxy, name, description, unit)
            % Private constructor. Use createUpDownCounter method of Meter
            % to create UpDownCounters.
            obj@opentelemetry.metrics.SynchronousInstrument(proxy, name, description, unit);
        end
    end
       
    methods
        function add(obj, value, varargin)
            % input value must be a numerical scalar
            if isnumeric(value) && isscalar(value)
                if nargin == 2
                    obj.Proxy.add(value);
                elseif isa(varargin{1}, "dictionary")
                    attrkeys = keys(varargin{1});
                    attrvals = values(varargin{1},"cell");
                    if all(cellfun(@iscell, attrvals))
                        attrvals = [attrvals{:}];
                    end
                    obj.Proxy.add(value, attrkeys, attrvals);
                else
                    attrkeys = [varargin{1:2:length(varargin)}]';
                    attrvals = [varargin(2:2:length(varargin))]';
                    obj.Proxy.add(value, attrkeys, attrvals);
                end
            end
        end
    end
end