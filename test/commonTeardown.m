function commonTeardown(testCase)
% Teardown function for tests
%
% Copyright 2023 The MathWorks, Inc.

% Terminate Collector if it is still running
terminateCollector(testCase);

% On Windows, a command prompt has popped up, remove it as clean up
if ispc
    system(testCase.TestData.list("cmd") + "  > " + testCase.TestData.pidfile);
    tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
    pid = tbl.Var2(end-1);
    system(testCase.TestData.sigterm(pid));
end

if exist(testCase.TestData.jsonfile, "file")
    delete(testCase.TestData.jsonfile);
end
if exist(testCase.TestData.pidfile, "file")
    delete(testCase.TestData.pidfile);
end