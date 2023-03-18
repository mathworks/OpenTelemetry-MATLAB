classdef AlwaysOffSampler
% AlwaysOffSampler excludes all samples and includes none.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.trace.TracerProvider,...
            ?opentelemetry.sdk.trace.ParentBasedSampler})
        Proxy
    end

    methods
        function obj = AlwaysOffSampler()
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.AlwaysOffSamplerProxy", ...
                "ConstructorArguments", {});
        end
    end
end
