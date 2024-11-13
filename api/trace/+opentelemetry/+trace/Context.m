classdef Context
% Tracing-related actions on context instances

% Copyright 2023-2024 The MathWorks, Inc.

    methods (Static)
        function sp = extractSpan(context)
            % Extract span from context
            %    SP = OPENTELEMETRY.TRACE.CONTEXT.EXTRACTSPAN(CTXT) extracts
            %    span SP from a context object CTXT. If CTXT does not 
            %    contain any spans, SP will be an invalid span with all-zero
            %    trace and span IDs.
            %
            %    See also INSERTSPAN, OPENTELEMETRY.CONTEXT.CONTEXT
            arguments
                context (1,1) opentelemetry.context.Context
            end
            sp = opentelemetry.trace.Span(context);
        end

        function context = insertSpan(context, span)
            % Insert span into context
            %    NEWCTXT = OPENTELEMETRY.TRACE.CONTEXT.INSERTSPAN(CTXT, SP) inserts
            %    span or span context SP into a context object CTXT and returns a new context. 
            %
            %    See also EXTRACTSPAN, OPENTELEMETRY.CONTEXT.CONTEXT
            arguments
                context (1,1) opentelemetry.context.Context
                span (1,1) {mustBeA(span, ["opentelemetry.trace.Span", "opentelemetry.trace.SpanContext"])}
            end
            context = span.insertSpan(context);  % call span method
        end
    end

end
