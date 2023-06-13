function jsonresults = readJsonResults(testCase)
% Read Json results exported by OpenTelemetry Collector
%
% Copyright 2023 The MathWorks, Inc.

terminateCollector(testCase);

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