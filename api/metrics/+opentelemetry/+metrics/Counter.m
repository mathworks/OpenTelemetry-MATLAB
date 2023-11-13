classdef Counter < opentelemetry.metrics.SynchronousInstrument
    % Counter is a value that accumulates over time and can only increase
    % but not decrease.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access={?opentelemetry.metrics.Meter})
        function obj = Counter(proxy, name, description, unit)
            % Private constructor. Use createCounter method of Meter
            % to create Counters.
            obj@opentelemetry.metrics.SynchronousInstrument(proxy, name, description, unit);
        end
    end
       
    methods
        function add(obj, value, varargin)
            obj.processValue(value, varargin{:});
        end
    end
end