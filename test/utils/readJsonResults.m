function jsonresults = readJsonResults(testCase)
% Read Json results exported by OpenTelemetry Collector
%
% Copyright 2023 The MathWorks, Inc.

terminateCollector(testCase);

assert(exist(testCase.JsonFile, "file"));

fid = fopen(testCase.JsonFile);
raw = fread(fid, inf);
str = cellstr(strsplit(char(raw'),'\n'));
% discard the last cell, which is empty
str(end) = [];
fclose(fid);
jsonresults = cellfun(@jsondecode,str,"UniformOutput",false);
end