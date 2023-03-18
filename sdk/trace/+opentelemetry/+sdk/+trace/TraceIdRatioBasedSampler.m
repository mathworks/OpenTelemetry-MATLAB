classdef TraceIdRatioBasedSampler
% TraceIdRatioBasedSampler samples traces using their trace ID.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.trace.TracerProvider,...
            ?opentelemetry.sdk.trace.ParentBasedSampler})
        Proxy
    end

    properties (SetAccess=immutable)
        Ratio (1,1) double
    end

    methods
        function obj = TraceIdRatioBasedSampler(ratio)
            arguments
                ratio (1,1) {mustBeNumeric, mustBeNonnegative, mustBeLessThanOrEqual(ratio,1)}
            end
            ratio = double(ratio);
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.TraceIdRatioBasedSamplerProxy", ...
                "ConstructorArguments", {ratio});
            obj.Ratio = ratio;
        end
    end
end
