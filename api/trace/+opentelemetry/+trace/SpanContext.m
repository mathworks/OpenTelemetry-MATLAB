classdef SpanContext < handle
% The part of a span that is propagated.

% Copyright 2023 The MathWorks, Inc.

    properties (Dependent, SetAccess=private)
        TraceId (1,1) string
        SpanId (1,1)  string
    end

    properties (Access=?opentelemetry.trace.Tracer)
        Proxy
    end

    methods (Access=?opentelemetry.trace.Span)
        function obj = SpanContext(proxy)
            obj.Proxy = proxy;
        end
    end

    methods
        function traceid = get.TraceId(obj)
            traceid = obj.Proxy.getTraceId();
        end

        function spanid = get.SpanId(obj)
            spanid = obj.Proxy.getSpanId();
        end

        function tf = isSampled(obj)
            tf = obj.Proxy.isSampled();
        end

        function tf = isValid(obj)
            tf = obj.Proxy.isValid();
        end

        function tf = isRemote(obj)
            tf = obj.Proxy.isRemote();
        end
    end

end
