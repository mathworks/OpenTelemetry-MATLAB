classdef SpanContext < handle
% The part of a span that is propagated.

% Copyright 2023 The MathWorks, Inc.

    properties (Dependent, SetAccess=private)
        TraceId (1,1) string     % Trace identifier represented as a string of 32 hexadecimal digits
        SpanId (1,1)  string     % Span identifier represented as a string of 16 hexadecimal digits
        TraceState (1,1) string  % Vendor-specific trace identification data, specified as comma-separated name-value pairs
        TraceFlags (1,1) string  % Details about the trace, such as a flag that represents whether the span is sampled
    end

    properties (Access=?opentelemetry.trace.Tracer)
        Proxy   % Proxy object to interface C++ code
    end   

    methods (Access={?opentelemetry.trace.Span,?opentelemetry.trace.Link})
        function obj = SpanContext(proxy)
            if nargin < 1
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.SpanContextProxy", ...
                    "ConstructorArguments", {});
            else
                obj.Proxy = proxy;
            end
        end
    end

    methods
        function traceid = get.TraceId(obj)
            traceid = obj.Proxy.getTraceId();
        end

        function spanid = get.SpanId(obj)
            spanid = obj.Proxy.getSpanId();
        end

        function tracestate = get.TraceState(obj)
            tracestate = obj.Proxy.getTraceState();
        end

        function traceflags = get.TraceFlags(obj)
            traceflags = obj.Proxy.getTraceFlags();
        end

        function tf = isSampled(obj)
            % ISSAMPLED  Whether span is sampled.
            %    TF = ISSAMPLED(SPCTXT)  returns true or false to indicate
            %    whether span is sampled.
            %
            %    See also ISVALID, ISREMOTE
            tf = obj.Proxy.isSampled();
        end

        function tf = isValid(obj)
            % ISVALID  Whether span is valid.
            %    TF = ISVALID(SPCTXT) returns true or false to indicate
            %    whether span has valid and non-zero trace and span IDs.
            %
            %    See also ISSAMPLED, ISREMOTE
            tf = obj.Proxy.isValid();
        end

        function tf = isRemote(obj)
            % ISREMOTE  Whether span context is propagated from a remote parent.
            %    TF = ISREMOTE(SPCTXT) returns true or false to indicate
            %    whether span context is propagated from a remote parent.
            %
            %    See also OPENTELEMETRY.CONTEXT.PROPAGATION.EXTRACTCONTEXT,
            %    ISSAMPLED, ISVALID
            tf = obj.Proxy.isRemote();
        end
    end

end
