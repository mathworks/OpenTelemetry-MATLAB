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
            % RECORD Aggregate a value into a histogram bin
            %    RECORD(H, VALUE) determine which bin VALUE falls into and
            %    increment that bin by 1.
            %
            %    RECORD(H, VALUE, ATTRIBUTES) also specifies attributes as a
            %    dictionary
            %
            %    RECORD(H, VALUE, ATTRNAME1, ATTRVALUE1, ATTRNAME2,
            %    ATTRVALUE2, ...) specifies attributes as trailing
            %    name-value pairs.
            obj.processValue(value, varargin{:});
        end
    end
end
