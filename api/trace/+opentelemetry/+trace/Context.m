classdef Context
% Tracing-related actions on context instances

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        % extract span from context
        function sp = extractSpan(context)
            arguments
                context (1,1) opentelemetry.context.Context
            end
            sp = opentelemetry.trace.Span(context);
        end

        % insert a span into context and return new context
        function context = insertSpan(context, span)
            arguments
                context (1,1) opentelemetry.context.Context
                span (1,1) opentelemetry.trace.Span
            end
            context = span.insertSpan(context);  % call span method
        end
    end

end
