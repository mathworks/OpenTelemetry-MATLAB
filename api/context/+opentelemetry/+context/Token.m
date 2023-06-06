classdef Token < handle
% Token object that controls the duration when a context is current. Upon
% deletion, the associated context will no longer be current.

% Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy    % Proxy object to interface C++ code
    end

    methods (Access=?opentelemetry.context.Context)
        function obj = Token(proxy)
            obj.Proxy = proxy;
        end
    end

end
