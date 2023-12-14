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
            % ADD Add to UpDownCounter value
            %    ADD(C, VALUE) adds scalar numeric value to the
            %    UpDownCounter. VALUE can be positive or negative.
            %
            %    ADD(C, VALUE, ATTRIBUTES) also specifies attributes as a
            %    dictionary
            %
            %    ADD(C, VALUE, ATTRNAME1, ATTRVALUE1, ATTRNAME2,
            %    ATTRVALUE2, ...) specifies attributes as trailing
            %    name-value pairs.
            obj.processValue(value, varargin{:});
        end
    end
end