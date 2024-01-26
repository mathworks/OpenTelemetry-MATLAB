classdef ObservableUpDownCounter < opentelemetry.metrics.AsynchronousInstrument
    % ObservableUpDownCounter is an asynchronous up-down-counter that 
    % records its value via a callback and its value can both increase and 
    % decrease.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access={?opentelemetry.metrics.Meter})
        
        function obj = ObservableUpDownCounter(proxy, name, description, unit, callback)
            % Private constructor. Use getObservableUpDownCounter method of Meter
            % to create observable up-down-counters.
            obj@opentelemetry.metrics.AsynchronousInstrument(proxy, name, ...
                description, unit, callback);
        end

    end
end
