function terminateProcess(testCase, process, terminatecmd)
% Terminate a process started in a test

% Copyright 2023-2024 The MathWorks, Inc.

if nargin < 3
    terminatecmd = testCase.Sigterm;  % defaults to terminate signal
end

system(testCase.ListPid(process) + " > " + testCase.PidFile);
tbl = testCase.ReadPidList(testCase.PidFile);
pid = testCase.ExtractPid(tbl);
retry = 0;
% sometimes kill will fail with a RuntimeError: windows-kill-library: ctrl-routine:findAddress:checkAddressIsNotNull 
% Retry up to 3 times
while ~isempty(pid) && retry < 4
    % kill all if multiple instances found
    for i = 1:numel(pid)
        system(terminatecmd(pid(i)));
    end
    pause(2);  % give a little time for the collector to shut down
    system(testCase.ListPid(process) + " > " + testCase.PidFile);
    tbl = testCase.ReadPidList(testCase.PidFile);
    pid = testCase.ExtractPid(tbl);
    retry = retry + 1;
end
