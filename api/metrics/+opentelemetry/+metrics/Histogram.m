classdef Histogram < opentelemetry.metrics.SynchronousInstrument
    % Histogram is an instrument that aggregates values into bins

    % Copyright 2023 The MathWorks, Inc.

    methods (Access={?opentelemetry.metrics.Meter})
        function obj = Histogram(proxy, name, description, unit)
            % Private constructor. Use createHistogram method of Meter
            % to create Histograms.
            obj@opentelemetry.metrics.SynchronousInstrument(proxy, name, description, unit);
        end
    end
       
    methods
        function record(obj, value, varargin)
            % input value must be a numerical scalar
            if isnumeric(value) && isscalar(value)
                if nargin == 2
                    obj.Proxy.record(value);
                elseif isa(varargin{1}, "dictionary")
                    attrkeys = keys(varargin{1});
                    attrvals = values(varargin{1},"cell");
                    if all(cellfun(@iscell, attrvals))
                        attrvals = [attrvals{:}];
                    end
                    obj.Proxy.record(value, attrkeys, attrvals);
                else
                    attrkeys = [varargin{1:2:length(varargin)}]';
                    attrvals = [varargin(2:2:length(varargin))]';
                    obj.Proxy.record(value, attrkeys, attrvals);
                end
            end
        end
    end
end
