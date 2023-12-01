classdef ObservableCounter < opentelemetry.metrics.AsynchronousInstrument
    % ObservableCounter is an asynchronous counter that records its value
    % via a callback and its value can only increase but not decrease

    % Copyright 2023 The MathWorks, Inc.

    methods (Access={?opentelemetry.metrics.Meter})
        
        function obj = ObservableCounter(proxy, name, description, unit, callback)
            % Private constructor. Use getObservableCounter method of Meter
            % to create observable counters.
            obj@opentelemetry.metrics.AsynchronousInstrument(proxy, name, ...
                description, unit, callback);
        end

    end
end
