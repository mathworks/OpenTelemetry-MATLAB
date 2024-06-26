function closeWindow(testCase)
% Close a command window

% Copyright 2024 The MathWorks, Inc.

% On Windows, a command prompt has popped up, remove it as clean up
if ispc
    system(testCase.ListPid("cmd") + "  > " + testCase.PidFile);
    tbl = testCase.ReadPidList(testCase.PidFile);
    if height(tbl) > 1
        pid = tbl.Var2(end-1);
        system(testCase.Sigterm(pid));
    end
end
end
