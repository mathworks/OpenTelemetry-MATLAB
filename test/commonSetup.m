function commonSetup(testCase)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

% start collector
system(testCase.Otelcol + " --config " + testCase.OtelConfigFile + '&');
pause(1);   % give a little time for Collector to start up