function commonSetupOnce(testCase)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

% file definitions
otelcolroot = getenv("OPENTELEMETRY_COLLECTOR_INSTALL");
testCase.TestData.otelconfigfile = fullfile(fileparts(mfilename("fullpath")), ...
    "otelcol_config.yml");
testCase.TestData.otelroot = getenv("OPENTELEMETRY_MATLAB_INSTALL");
testCase.TestData.jsonfile = "myoutput.json";
testCase.TestData.pidfile = "testoutput.txt";

% process definitions
testCase.TestData.otelcol = fullfile(otelcolroot, "otelcol");
if ispc
   testCase.TestData.list = @(name)"tasklist /fi ""IMAGENAME eq " + name + ".exe""";
   testCase.TestData.readlist = @(file)readtable(file, "VariableNamingRule", "preserve", "NumHeaderLines", 3, "MultipleDelimsAsOne", true, "Delimiter", " ");
   testCase.TestData.extractPid = @(table)table.Var2;
   windows_killroot = string(getenv("WINDOWS_KILL_INSTALL"));
   testCase.TestData.sigint = @(id)fullfile(windows_killroot,"windows-kill") + " -SIGINT " + id;
   testCase.TestData.sigterm = @(id)"taskkill /pid " + id;
elseif isunix && ~ismac
   testCase.TestData.list = @(name)"ps -C " + name;
   testCase.TestData.readlist = @readtable;
   testCase.TestData.extractPid = @(table)table.PID;
   testCase.TestData.sigint = @(id)"kill " + id;  % kill sends a SIGTERM instead of SIGINT but turns out this is sufficient to terminate OTEL collector on Linux
   testCase.TestData.sigterm = @(id)"kill " + id;
end

% set up path
addpath(testCase.TestData.otelroot);

% remove temporary files if present
if exist(testCase.TestData.jsonfile, "file")
    delete(testCase.TestData.jsonfile);
end
if exist(testCase.TestData.pidfile, "file")
    delete(testCase.TestData.pidfile);
end
