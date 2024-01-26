classdef ObservableGauge < opentelemetry.metrics.AsynchronousInstrument
    % ObservableGauge is an asynchronous gauge that report its values via a
    % callback and its value cannot be summed in aggregation.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access={?opentelemetry.metrics.Meter})
        
        function obj = ObservableGauge(proxy, name, description, unit, callback)
            % Private constructor. Use getObservableGauge method of Meter
            % to create observable gauges.
            obj@opentelemetry.metrics.AsynchronousInstrument(proxy, name, ...
                description, unit, callback);
        end

    end
end
