classdef Provider
% Get and set the global instance of logger provider

% Copyright 2024-2025 The MathWorks, Inc.

    methods (Static)
        function p = getLoggerProvider()
            % Get the global instance of logger provider
            %    LP = OPENTELEMETRY.LOGS.PROVIDER.GETLOGGERPROVIDER gets
            %    the global instance of logger provider.
            %
            %    See also OPENTELEMETRY.LOGS.PROVIDER.SETLOGGERPROVIDER

            p = opentelemetry.logs.LoggerProvider();
        end

        function setLoggerProvider(p)
            % Set the global instance of logger provider
            %    OPENTELEMETRY.LOGS.PROVIDER.SETLOGGERPROVIDER(LP) sets
            %    LP as the global instance of logger provider.
            %
            %    See also OPENTELEMETRY.LOGS.PROVIDER.GETLOGGERPROVIDER, 
            %    OPENTELEMETRY.LOGS.PROVIDER.UNSETLOGGERPROVIDER

            p.setLoggerProvider();
        end

        function unsetLoggerProvider()
            % Unset the global instance of logger provider, which disables
            % logging
            %    OPENTELEMETRY.LOGS.PROVIDER.UNSETLOGGERPROVIDER() unsets
            %    the global instance of logger provider.
            %
            %    See also OPENTELEMETRY.LOGS.PROVIDER.SETLOGGERPROVIDER

            opentelemetry.logs.internal.NoOpLoggerProvider;
        end
    end

end
