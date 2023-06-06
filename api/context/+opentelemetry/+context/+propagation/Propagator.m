classdef Propagator
% Get and set the global instance of TextMapPropagator

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function p = getTextMapPropagator()
            % Get the global instance of text map propagator
            %    PROP =
            %    OPENTELEMETRY.CONTEXT.PROPAGATION.PROPAGATOR.GETTEXTMAPPROPAGATOR
            %    returns the global instance of text map propagator.
            %
            %    See also
            %    OPENTELEMETRY.CONTEXT.PROPAGATION.PROPAGATOR.SETTEXTMAPPROPAGATOR
            p = opentelemetry.context.propagation.TextMapPropagator();
        end

        function setTextMapPropagator(p)
            % Set the global instance of text map propagator
            %    OPENTELEMETRY.CONTEXT.PROPAGATION.PROPAGATOR.SETTEXTMAPPROPAGATOR(PROP)
            %    sets text map propagator PROP as the global instance.
            %
            %    See also
            %    OPENTELEMETRY.CONTEXT.PROPAGATION.PROPAGATOR.GETTEXTMAPPROPAGATOR
            p.setTextMapPropagator();
        end
    end

end