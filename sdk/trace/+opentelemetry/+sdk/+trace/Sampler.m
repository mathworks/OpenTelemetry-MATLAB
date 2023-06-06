classdef Sampler
% Base class for samplers.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.trace.TracerProvider,...
            ?opentelemetry.sdk.trace.ParentBasedSampler})
        Proxy  % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = Sampler(proxyname, varargin)
            % Base class constructor
            obj.Proxy = libmexclass.proxy.Proxy("Name", proxyname, ...
                "ConstructorArguments", varargin);
        end
    end
end
