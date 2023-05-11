classdef Propagator
% Get and set the global instance of TextMapPropagator

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function p = getTextMapPropagator()
            p = opentelemetry.context.propagation.TextMapPropagator();
        end

        function setTextMapPropagator(p)
            p.setTextMapPropagator();
        end
    end

end