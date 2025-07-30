classdef NoOpLoggerProvider < handle
    % A no-op logger provider does nothing and is used to disable logging.
    % For internal use only.

    % Copyright 2025 The MathWorks, Inc.

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=?opentelemetry.logs.Provider)
        function obj = NoOpLoggerProvider()
            % constructs a no-op LoggerProvider and sets it as the global
            % instance
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.NoOpLoggerProviderProxy", ...
                "ConstructorArguments", {});
        end
    end
end
