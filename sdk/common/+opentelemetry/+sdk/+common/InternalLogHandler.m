classdef InternalLogHandler < handle
% Internal log handler enables changes to internal log message display

% Copyright 2024 The MathWorks, Inc.

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    properties (Access=private, Constant)
    	LogLevels = ["none" "error" "warning" "info" "debug"]
    end

    properties (Dependent)
        LogLevel (1,1) string % Supported levels from highest to lowest are 
                              % "none", "error", "warning", "info",
                              % "debug". Setting to a higher level displays
                              % fewer internal log messages.
    end

    methods
        function obj = InternalLogHandler()
            % Internal log handler enables changes to internal log message
            % display
            %    H = OPENTELEMETRY.SDK.COMMON.INTERNALLOGHANDLER creates an internal log handler.
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.InternalLogHandlerProxy", ...
                "ConstructorArguments", {});
        end

        function loglevel = get.LogLevel(obj)
            loglevel = obj.Proxy.getLogLevel();
        end

        function set.LogLevel(obj, loglevel)
    	    loglevel = validatestring(loglevel, obj.LogLevels);
            obj.Proxy.setLogLevel(loglevel);
        end
    end
end
