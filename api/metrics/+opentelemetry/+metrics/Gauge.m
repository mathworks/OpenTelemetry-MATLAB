classdef Gauge < opentelemetry.metrics.SynchronousInstrument
    % Gauge is an instrument for recording non-aggregatable measurements.

    % Copyright 2025 The MathWorks, Inc.

    methods (Access={?opentelemetry.metrics.Meter})
        function obj = Gauge(proxy, name, description, unit)
            % Private constructor. Use createGauge method of Meter
            % to create gauges.
            obj@opentelemetry.metrics.SynchronousInstrument(proxy, name, description, unit);
        end
    end
       
    methods
        function record(obj, value, varargin)
            % RECORD Record a value
            %    RECORD(G, VALUE) records a scalar numeric value. VALUE can be positive or negative.
            %
            %    RECORD(G, VALUE, ATTRIBUTES) also specifies attributes as a
            %    dictionary
            %
            %    RECORD(G, VALUE, ATTRNAME1, ATTRVALUE1, ATTRNAME2,
            %    ATTRVALUE2, ...) specifies attributes as trailing
            %    name-value pairs.
            obj.processValue(value, varargin{:});
        end
    end
end