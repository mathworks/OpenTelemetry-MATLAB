classdef AlwaysOnSampler < opentelemetry.sdk.trace.Sampler
% AlwaysOnSampler includes all samples and excludes none.

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = AlwaysOnSampler()
            obj = obj@opentelemetry.sdk.trace.Sampler(...
                "libmexclass.opentelemetry.sdk.AlwaysOnSamplerProxy");
        end
    end
end
