classdef AlwaysOffSampler < opentelemetry.sdk.trace.Sampler
% AlwaysOffSampler excludes all samples and includes none.

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = AlwaysOffSampler()
            % AlwaysOffSampler Sampler that excludes all samples and includes none.
            %    S = OPENTELEMETRY.SDK.TRACE.ALWAYSOFFSAMPLER creates an 
            %    AlwaysOffSampler instance.
            %
            %    See also OPENTELEMETRY.SDK.TRACE.ALWAYSONSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.TRACERIDRATIOBASEDSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.PARENTBASEDSAMPLER
            obj = obj@opentelemetry.sdk.trace.Sampler(...
                "libmexclass.opentelemetry.sdk.AlwaysOffSamplerProxy");
        end
    end
end
