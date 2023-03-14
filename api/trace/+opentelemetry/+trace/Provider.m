classdef Provider
% Get and set the global instance of tracer provider

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function p = getTracerProvider()
            p = opentelemetry.trace.TracerProvider();
        end

        function setTracerProvider(p)
            p.setTracerProvider();
        end
    end

end
