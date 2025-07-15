classdef NoOpTracerProvider < handle
    % A no-op tracer provider does nothing and is used to disable tracing.
    % For internal use only.

    % Copyright 2025 The MathWorks, Inc.

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=?opentelemetry.trace.Provider)
        function obj = NoOpTracerProvider()
            % constructs a no-op TracerProvider and sets it as the global
            % instance
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.NoOpTracerProviderProxy", ...
                "ConstructorArguments", {});
        end
    end
end
