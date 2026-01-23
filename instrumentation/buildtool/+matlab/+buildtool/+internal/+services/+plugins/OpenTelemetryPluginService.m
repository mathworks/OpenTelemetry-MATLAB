classdef OpenTelemetryPluginService < matlab.buildtool.internal.services.plugins.BuildRunnerPluginService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2026 The MathWorks, Inc.

    methods
        function plugins = providePlugins(~, ~)
            plugins = matlab.buildtool.plugins.BuildRunnerPlugin.empty(1,0);
            if ~isMATLABReleaseOlderThan("R2026a")
                plugins = matlab.buildtool.plugins.OpenTelemetryPlugin();
            end
        end
    end
end