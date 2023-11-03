classdef SynchronousInstrument < handle
    % Base class inherited by all synchronous instruments

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name        (1,1) string  
        Description (1,1) string   
        Unit        (1,1) string   
    end

    properties (Access=protected)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = SynchronousInstrument(proxy, name, description, unit)
            obj.Proxy = proxy;
            obj.Name = name;
            obj.Description = description;
            obj.Unit = unit;
        end
    end
end