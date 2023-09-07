classdef Histogram < handle
    % Histogram is an instrument that adds or reduce values.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name        (1,1) string  
        Description (1,1) string   
        Unit        (1,1) string   
    end

    properties (Access=public)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.metrics.Meter})
        
        function obj = Histogram(proxy, hiname, hidescription, hiunit)
            % Private constructor. Use createHistogram method of Meter
            % to create Histograms.
            obj.Proxy = proxy;
            obj.Name = hiname;
            obj.Description = hidescription;
            obj.Unit = hiunit;
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
                    obj.Proxy.record(value,attrkeys,attrvals);
                else
                    attrkeys = [varargin{1:2:length(varargin)}]';
                    attrvals = [varargin(2:2:length(varargin))]';
                    obj.Proxy.record(value,attrkeys,attrvals);
                end
            end
            
        end

    end

        
end
