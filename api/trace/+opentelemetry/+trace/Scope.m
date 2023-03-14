classdef Scope
% Controls the duration when a span is current

% Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy
    end

    properties (Hidden)
        Cleanup
    end

    methods (Access=?opentelemetry.trace.Span)
        function obj = Scope(proxy)
            obj.Proxy = proxy;
            obj.Cleanup = onCleanup(@()delete(obj.Proxy));
        end
    end

end
