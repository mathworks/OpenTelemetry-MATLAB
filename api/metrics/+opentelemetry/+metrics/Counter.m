classdef Counter < handle
   

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name        (1,1) string  
        Description (1,1) string   
        Unit        (1,1) string   
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.metrics.Meter})
        
        function obj = Counter(proxy, ctname, ctdescription, ctunit)
            % Private constructor. Use getCounter method of Meter
            % to create Counters.
            obj.Proxy = proxy;
            obj.Name = ctname;
            obj.Description = ctdescription;
            obj.Unit = ctunit;
        end

    end

    methods
        
        function add(obj, value)
            if isnumeric(value) && isscalar(value)
                obj.Proxy.add(value);
            end
        end

    end

        
end
