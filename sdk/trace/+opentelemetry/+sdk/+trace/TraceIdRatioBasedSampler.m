classdef TraceIdRatioBasedSampler < opentelemetry.sdk.trace.Sampler
% TraceIdRatioBasedSampler samples traces using their trace ID.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Ratio (1,1) double  % Sampling ratio between 0 and 1
    end

    methods
        function obj = TraceIdRatioBasedSampler(ratio)
            % TraceIdRatioBasedSampler samples traces using their trace ID.
            %    S = OPENTELEMETRY.SDK.TRACE.TRACEIDRATIOBASEDSAMPLER(RATIO) specifies a sampling
            %    ratio between 0 (excludes all samples) and 1 (includes all samples).
            %
            %    See also OPENTELEMETRY.SDK.TRACE.ALWAYSONSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.ALWAYSOFFSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.PARENTBASEDSAMPLER
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
