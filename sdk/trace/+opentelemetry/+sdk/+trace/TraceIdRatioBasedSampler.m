classdef TraceIdRatioBasedSampler
% TraceIdRatioBasedSampler samples traces using their trace ID.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess=?opentelemetry.sdk.trace.TracerProvider)
        Proxy
    end

    methods
        function obj = TraceIdRatioBasedSampler(ratio)
            arguments
                ratio (1,1) {mustBeNumeric, mustBeNonnegative, mustBeLessThanOrEqual(ratio,1)}
            end
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.TraceIdRatioBasedSamplerProxy", ...
                "ConstructorArguments", {ratio});
        end
    end
end
