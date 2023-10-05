classdef Provider
% Get and set the global instance of meter provider

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function p = getMeterProvider()
            % Get the global instance of meter provider
            %    MP = OPENTELEMETRY.METRICS.PROVIDER.GETMETERPROVIDER gets
            %    the global instance of meter provider.
            %
            %    See also OPENTELEMETRY.METRICS.PROVIDER.SETMETERPROVIDER

            p = opentelemetry.metrics.MeterProvider();
        end

        function setMeterProvider(p)
            % Set the global instance of meter provider
            %    OPENTELEMETRY.METRICS.PROVIDER.GETMETERPROVIDER(MP) sets
            %    MP as the global instance of meter provider.
            %
            %    See also OPENTELEMETRY.METRICS.PROVIDER.GETMETERPROVIDER
            p.setMeterProvider();
        end
    end

end
