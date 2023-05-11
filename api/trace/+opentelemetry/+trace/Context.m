classdef Context
% Tracing-related actions on context instances

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function sp = extractSpan(context)
            arguments
                context (1,1) opentelemetry.context.Context
            end
            sp = opentelemetry.trace.Span(context);
        end
    end

end
