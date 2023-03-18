classdef AlwaysOnSampler
% AlwaysOnSampler includes all samples and excludes none.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.trace.TracerProvider,...
            ?opentelemetry.sdk.trace.ParentBasedSampler})
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
