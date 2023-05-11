classdef Token < handle
% Token object that controls the duration when a context is current

% Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy
    end

    methods (Access=?opentelemetry.context.Context)
        function obj = Token(proxy)
            obj.Proxy = proxy;
        end
    end

end
