function commonTeardown(testCase)
% Teardown function for tests
%
% Copyright 2023 The MathWorks, Inc.

% Terminate Collector if it is still running
terminateCollector(testCase);

% On Windows, a command prompt has popped up, remove it as clean up
if ispc
    system(testCase.ListPid("cmd") + "  > " + testCase.PidFile);
    tbl = testCase.ReadPidList(testCase.PidFile);
    pid = tbl.Var2(end-1);
    system(testCase.Sigterm(pid));
end

if exist(testCase.JsonFile, "file")
    delete(testCase.JsonFile);
end
if exist(testCase.PidFile, "file")
    delete(testCase.PidFile);
end
