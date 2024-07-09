function commonTeardown(testCase)
% Teardown function for tests

% Copyright 2023-2024 The MathWorks, Inc.

% Terminate Collector if it is still running. Use interrupt signal.
terminateProcess(testCase, testCase.OtelcolName, testCase.Sigint);

% Close command window if opened
closeWindow(testCase);

if exist(testCase.JsonFile, "file")
    delete(testCase.JsonFile);
end
if exist(testCase.PidFile, "file")
    delete(testCase.PidFile);
end
