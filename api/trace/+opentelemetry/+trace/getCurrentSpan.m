function sp = getCurrentSpan()
% Retrieve the current span
%    SP = OPENTELEMETRY.TRACE.GETCURRENTSPAN() returns the current span.
%    If there is not current span, SP will be an invalid span with all-zero
%    trace and span IDs.
%
%    See also OPENTELEMETRY.TRACE.SPAN,
%    OPENTELEMETRY.CONTEXT.GETCURRENTCONTEXT
%    OPENTELEMETRY.TRACE.CONTEXT.EXTRACTSPAN

% Copyright 2024 The MathWorks, Inc.

ctx = opentelemetry.context.getCurrentContext;
sp = opentelemetry.trace.Context.extractSpan(ctx);
