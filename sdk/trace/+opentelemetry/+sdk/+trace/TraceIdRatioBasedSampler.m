classdef TraceIdRatioBasedSampler < opentelemetry.sdk.trace.Sampler
% TraceIdRatioBasedSampler samples traces using their trace ID.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Ratio (1,1) double
    end

    methods
        function obj = TraceIdRatioBasedSampler(ratio)
            arguments
                ratio (1,1) {mustBeNumeric, mustBeNonnegative, mustBeLessThanOrEqual(ratio,1)}
            end
            ratio = double(ratio);
            obj = obj@opentelemetry.sdk.trace.Sampler(...
                "libmexclass.opentelemetry.sdk.TraceIdRatioBasedSamplerProxy", ratio);
            obj.Ratio = ratio;
        end
    end
end
