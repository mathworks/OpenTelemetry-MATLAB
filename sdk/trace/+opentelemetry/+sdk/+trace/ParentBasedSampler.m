classdef ParentBasedSampler < opentelemetry.sdk.trace.Sampler
% ParentBasedSampler is a composite sampler. Non-root spans respect their
% parent spans' sampling decision, and root spans delegate to the
% delegate sampler.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        DelegateSampler 
    end

    methods
        function obj = ParentBasedSampler(delegate)
            arguments
                delegate (1,1) {mustBeA(delegate,["opentelemetry.sdk.trace.AlwaysOnSampler",...
                    "opentelemetry.sdk.trace.AlwaysOffSampler",...
                    "opentelemetry.sdk.trace.TraceIdRatioBasedSampler"])}
            end
            delegate_id = delegate.Proxy.ID;
            obj = obj@opentelemetry.sdk.trace.Sampler(...
                "libmexclass.opentelemetry.sdk.ParentBasedSamplerProxy", delegate_id);
            obj.DelegateSampler = delegate;
        end
    end
end
