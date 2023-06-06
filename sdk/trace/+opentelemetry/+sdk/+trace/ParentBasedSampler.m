classdef ParentBasedSampler < opentelemetry.sdk.trace.Sampler
% ParentBasedSampler is a composite sampler. Non-root spans respect their
% parent spans' sampling decision, and root spans delegate to the
% delegate sampler.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        DelegateSampler  % Delegate sampler specifies sampling policy of root spans.
    end

    methods
        function obj = ParentBasedSampler(delegate)
            % ParentBasedSampler is a composite sampler. Non-root spans respect their parent spans' sampling decision, and root spans delegate to the delegate sampler.
            %    S = OPENTELEMETRY.SDK.TRACE.PARENTBASEDSAMPLER(DELEGATE) 
            %    specifies the delegate sampler that is applied to root spans.
            %
            %    See also OPENTELEMETRY.SDK.TRACE.ALWAYSONSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.ALWAYSOFFSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.TRACEIDRATIOBASEDSAMPLER
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
