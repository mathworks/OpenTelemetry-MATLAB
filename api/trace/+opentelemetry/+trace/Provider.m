classdef Provider
% Get and set the global instance of tracer provider

% Copyright 2023-2025 The MathWorks, Inc.

    methods (Static)
        function p = getTracerProvider()
            % Get the global instance of tracer provider
            %    TP = OPENTELEMETRY.TRACE.PROVIDER.GETTRACERPROVIDER gets
            %    the global instance of tracer provider.
            %
            %    See also OPENTELEMETRY.TRACE.PROVIDER.SETTRACERPROVIDER

            p = opentelemetry.trace.TracerProvider();
        end

        function setTracerProvider(p)
            % Set the global instance of tracer provider
            %    OPENTELEMETRY.TRACE.PROVIDER.SETTRACERPROVIDER(TP) sets
            %    TP as the global instance of tracer provider.
            %
            %    See also OPENTELEMETRY.TRACE.PROVIDER.GETTRACERPROVIDER, 
            %    OPENTELEMETRY.TRACE.PROVIDER.UNSETTRACERPROVIDER

            p.setTracerProvider();
        end

        function unsetTracerProvider()
            % Unset the global instance of tracer provider, which disables
            % tracing
            %    OPENTELEMETRY.TRACE.PROVIDER.UNSETTRACERPROVIDER() unsets
            %    the global instance of tracer provider.
            %
            %    See also OPENTELEMETRY.TRACE.PROVIDER.SETTRACERPROVIDER

            opentelemetry.trace.internal.NoOpTracerProvider;
        end
    end

end
