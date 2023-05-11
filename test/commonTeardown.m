function commonTeardown(testCase)
% Teardown function for tests
%
% Copyright 2023 The MathWorks, Inc.

% On Windows, a command prompt has popped up, remove it as clean up
if ispc
    system(testCase.TestData.list("cmd") + "  > " + testCase.TestData.pidfile);
    tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
    pid = tbl.Var2(end-1);
    system(testCase.TestData.sigterm(pid));
end

delete(testCase.TestData.jsonfile);
delete(testCase.TestData.pidfile);