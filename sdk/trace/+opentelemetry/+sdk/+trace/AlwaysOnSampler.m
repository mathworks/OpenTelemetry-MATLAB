classdef AlwaysOnSampler
% AlwaysOnSampler includes all samples and excludes none.

% Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy
    end

    methods
        function obj = AlwaysOnSampler()
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.AlwaysOnSamplerProxy", ...
                "ConstructorArguments", {});
        end
    end
end
