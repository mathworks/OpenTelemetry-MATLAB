function commonSetup(testCase, configfile)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

if nargin < 2
    configfile = testCase.OtelConfigFile;
end

% start collector
system(testCase.Otelcol + " --config " + configfile + '&');
pause(1);   % give a little time for Collector to start up