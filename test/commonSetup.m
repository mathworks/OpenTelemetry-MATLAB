function commonSetup(testCase)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

% start collector
system(testCase.TestData.otelcol + " --config " + testCase.TestData.otelconfigfile + '&');
pause(1);   % give a little time for Collector to start up