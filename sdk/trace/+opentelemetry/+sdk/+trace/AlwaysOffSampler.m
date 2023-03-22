classdef AlwaysOffSampler < opentelemetry.sdk.trace.Sampler
% AlwaysOffSampler excludes all samples and includes none.

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = AlwaysOffSampler()
            obj = obj@opentelemetry.sdk.trace.Sampler(...
                "libmexclass.opentelemetry.sdk.AlwaysOffSamplerProxy");
        end
    end
end
