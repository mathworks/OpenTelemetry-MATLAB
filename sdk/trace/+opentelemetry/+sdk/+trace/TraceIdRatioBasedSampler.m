classdef TraceIdRatioBasedSampler < opentelemetry.sdk.trace.Sampler
% TraceIdRatioBasedSampler samples traces using their trace ID.

% Copyright 2023 The MathWorks, Inc.

    properties
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
            
            obj.Ratio = ratio;
        end

        function obj = set.Ratio(obj, ratio)
            if ~(ratio >= 0 && ratio <= 1)
                error("opentelemetry:sdk:trace:TraceIdRatioBasedSampler:InvalidRatio", ...
                    "Ratio must be a numeric scalar between 0 and 1.");
            end
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.TraceIdRatioBasedSamplerProxy", ...
                "ConstructorArguments", {ratio});
            obj.Ratio = ratio;
        end
    end
end
