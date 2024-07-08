classdef SuppressInternalLogs < handle
    properties (Access=private)
        LogHandler
        SavedLogLevel
    end

    methods
        function obj = SuppressInternalLogs()
            obj.LogHandler = opentelemetry.sdk.common.InternalLogHandler;
            obj.SavedLogLevel = obj.LogHandler.LogLevel;
            obj.LogHandler.LogLevel = "none";
        end

        function delete(obj)
            obj.LogHandler.LogLevel = obj.SavedLogLevel;
        end
    end
end