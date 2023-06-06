classdef Provider
% Get and set the global instance of tracer provider

% Copyright 2023 The MathWorks, Inc.

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
            %    OPENTELEMETRY.TRACE.PROVIDER.GETTRACERPROVIDER(TP) sets
            %    TP as the global instance of tracer provider.
            %
            %    See also OPENTELEMETRY.TRACE.PROVIDER.GETTRACERPROVIDER

            p.setTracerProvider();
        end
    end

end
