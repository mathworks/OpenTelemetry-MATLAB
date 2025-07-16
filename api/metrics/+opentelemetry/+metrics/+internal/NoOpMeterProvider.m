classdef NoOpMeterProvider < handle
    % A no-op meter provider does nothing and is used to disable metrics.
    % For internal use only.

    % Copyright 2025 The MathWorks, Inc.

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=?opentelemetry.metrics.Provider)
        function obj = NoOpMeterProvider()
            % constructs a no-op MeterProvider and sets it as the global
            % instance
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.NoOpMeterProviderProxy", ...
                "ConstructorArguments", {});
        end
    end
end
