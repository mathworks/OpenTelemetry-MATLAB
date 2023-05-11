function jsonresults = readJsonResults(testCase)
% Read Json results exported by OpenTelemetry Collector
%
% Copyright 2023 The MathWorks, Inc.

system(testCase.TestData.list("otelcol") + " > " + testCase.TestData.pidfile);

tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
pid = testCase.TestData.extractPid(tbl);
system(testCase.TestData.sigint(pid));

% check if kill succeeded as it can sporadically fail
system(testCase.TestData.list("otelcol") + " > " + testCase.TestData.pidfile);
tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
pid = testCase.TestData.extractPid(tbl);
retry = 0;
% sometimes kill will fail with a RuntimeError: windows-kill-library: ctrl-routine:findAddress:checkAddressIsNotNull 
% in that case, retry up to 3 times
while ~isempty(pid) && retry < 3
    system(testCase.TestData.sigint(pid));
    tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
    pid = testCase.TestData.extractPid(tbl);
    retry = retry + 1;
end

pause(1);
assert(exist(testCase.TestData.jsonfile, "file"));

fid = fopen(testCase.TestData.jsonfile);
raw = fread(fid, inf);
str = cellstr(strsplit(char(raw'),'\n'));
% discard the last cell, which is empty
str(end) = [];
fclose(fid);
jsonresults = cellfun(@jsondecode,str,"UniformOutput",false);
end