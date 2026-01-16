classdef Sampler < handle
% Base class for samplers.

% Copyright 2023-2026 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.trace.TracerProvider,...
            ?opentelemetry.sdk.trace.ParentBasedSampler, ...
            ?opentelemetry.sdk.trace.TraceIdRatioBasedSampler})
        Proxy  % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = Sampler(proxyname, varargin)
            % Base class constructor
            if nargin > 0
                obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                    "ConstructorArguments", varargin);
            end
        end
    end
end
