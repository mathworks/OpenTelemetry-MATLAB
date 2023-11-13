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
            obj.processValue(value, varargin{:});
        end
    end
end
