function terminateCollector(testCase)
% Terminate OpenTelemetry Collector before reading results or as part of
% cleanup
%
% Copyright 2023 The MathWorks, Inc.

system(testCase.ListPid(testCase.OtelcolName) + " > " + testCase.PidFile);
tbl = testCase.ReadPidList(testCase.PidFile);
pid = testCase.ExtractPid(tbl);
retry = 0;
% sometimes kill will fail with a RuntimeError: windows-kill-library: ctrl-routine:findAddress:checkAddressIsNotNull 
% Retry up to 3 times
while ~isempty(pid) && retry < 4
    system(testCase.Sigint(pid));
    pause(2);  % give a little time for the collector to shut down
    system(testCase.ListPid(testCase.OtelcolName) + " > " + testCase.PidFile);
    tbl = testCase.ReadPidList(testCase.PidFile);
    pid = testCase.ExtractPid(tbl);
    retry = retry + 1;
end
