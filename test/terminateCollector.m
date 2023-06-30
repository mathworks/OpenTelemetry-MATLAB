function terminateCollector(testCase)
% Terminate OpenTelemetry Collector before reading results or as part of
% cleanup
%
% Copyright 2023 The MathWorks, Inc.

system(testCase.list("otelcol") + " > " + testCase.pidfile);
tbl = testCase.readlist(testCase.pidfile);
pid = testCase.extractPid(tbl);
retry = 0;
% sometimes kill will fail with a RuntimeError: windows-kill-library: ctrl-routine:findAddress:checkAddressIsNotNull 
% Retry up to 3 times
while ~isempty(pid) && retry < 4
    system(testCase.sigint(pid));
    pause(2);  % give a little time for the collector to shut down
    system(testCase.list("otelcol") + " > " + testCase.pidfile);
    tbl = testCase.readlist(testCase.pidfile);
    pid = testCase.extractPid(tbl);
    retry = retry + 1;
end