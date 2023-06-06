classdef AlwaysOnSampler < opentelemetry.sdk.trace.Sampler
% AlwaysOnSampler includes all samples and excludes none.

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = AlwaysOnSampler()
            % AlwaysOnSampler Sampler that includes all samples and excludes none.
            %    S = OPENTELEMETRY.SDK.TRACE.ALWAYSONSAMPLER creates an AlwaysOnSampler instance.
            %
            %    See also OPENTELEMETRY.SDK.TRACE.ALWAYSOFFSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.TRACERIDRATIOBASEDSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.PARENTBASEDSAMPLER
            obj = obj@opentelemetry.sdk.trace.Sampler(...
                "libmexclass.opentelemetry.sdk.AlwaysOnSamplerProxy");
        end
    end
end
