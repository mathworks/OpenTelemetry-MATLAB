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
            obj.processValue(value, varargin{:});
        end
    end
end