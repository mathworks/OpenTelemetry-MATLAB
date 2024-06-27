function jsonresults = readJsonResults(testCase)
% Read JSON results exported by OpenTelemetry Collector

% Copyright 2023-2024 The MathWorks, Inc.

% terminate the collector, using interrupt signal
terminateProcess(testCase, testCase.OtelcolName, testCase.Sigint);

assert(exist(testCase.JsonFile, "file"));

fid = fopen(testCase.JsonFile);
raw = fread(fid, inf);
str = cellstr(strsplit(char(raw'),'\n'));
% discard the last cell, which is empty
str(end) = [];
fclose(fid);
jsonresults = cellfun(@jsondecode,str,"UniformOutput",false);
end
