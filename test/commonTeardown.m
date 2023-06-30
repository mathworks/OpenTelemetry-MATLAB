function commonTeardown(testCase)
% Teardown function for tests
%
% Copyright 2023 The MathWorks, Inc.

% Terminate Collector if it is still running
terminateCollector(testCase);

% On Windows, a command prompt has popped up, remove it as clean up
if ispc
    system(testCase.list("cmd") + "  > " + testCase.pidfile);
    tbl = testCase.readlist(testCase.pidfile);
    pid = tbl.Var2(end-1);
    system(testCase.sigterm(pid));
end

if exist(testCase.jsonfile, "file")
    delete(testCase.jsonfile);
end
if exist(testCase.pidfile, "file")
    delete(testCase.pidfile);
end