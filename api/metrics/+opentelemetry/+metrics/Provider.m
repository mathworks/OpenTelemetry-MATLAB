classdef Provider
% Get and set the global instance of meter provider

% Copyright 2023-2025 The MathWorks, Inc.

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
            %    See also OPENTELEMETRY.METRICS.PROVIDER.GETMETERPROVIDER, 
            %    OPENTELEMETRY.METRICS.PROVIDER.UNSETMETERPROVIDER
            p.setMeterProvider();
        end

        function unsetMeterProvider()
            % Unset the global instance of meter provider, which disables
            % metrics
            %    OPENTELEMETRY.METRICS.PROVIDER.UNSETMETERPROVIDER() unsets
            %    the global instance of meter provider.
            %
            %    See also OPENTELEMETRY.METRICS.PROVIDER.SETMETERPROVIDER

            opentelemetry.metrics.internal.NoOpMeterProvider;
        end
    end

end
