function commonSetupOnce(testCase)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

% file definitions
otelcolroot = getenv("OPENTELEMETRY_COLLECTOR_INSTALL");
testCase.OtelConfigFile = fullfile(fileparts(mfilename("fullpath")), ...
    "otelcol_config.yml");
testCase.OtelRoot = getenv("OPENTELEMETRY_MATLAB_INSTALL");
testCase.JsonFile = "myoutput.json";
testCase.PidFile = "testoutput.txt";

% process definitions
testCase.Otelcol = fullfile(otelcolroot, "otelcol");
if ispc
   testCase.ListPid = @(name)"tasklist /fi ""IMAGENAME eq " + name + ".exe""";
   testCase.ReadPidList = @(file)readtable(file, "VariableNamingRule", "preserve", "NumHeaderLines", 3, "MultipleDelimsAsOne", true, "Delimiter", " ");
   testCase.ExtractPid = @(table)table.Var2;
   windows_killroot = string(getenv("WINDOWS_KILL_INSTALL"));
   testCase.Sigint = @(id)fullfile(windows_killroot,"windows-kill") + " -SIGINT " + id;
   testCase.Sigterm = @(id)"taskkill /pid " + id;
elseif isunix && ~ismac
   testCase.ListPid = @(name)"ps -C " + name;
   testCase.ReadPidList = @readtable;
   testCase.ExtractPid = @(table)table.PID;
   testCase.Sigint = @(id)"kill " + id;  % kill sends a SIGTERM instead of SIGINT but turns out this is sufficient to terminate OTEL collector on Linux
   testCase.Sigterm = @(id)"kill " + id;
end

% set up path
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(testCase.OtelRoot));

% remove temporary files if present
if exist(testCase.JsonFile, "file")
    delete(testCase.JsonFile);
end
if exist(testCase.PidFile, "file")
    delete(testCase.PidFile);
end
