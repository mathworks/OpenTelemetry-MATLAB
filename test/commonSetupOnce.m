function commonSetupOnce(testCase)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

% file definitions
otelcolroot = getenv("OPENTELEMETRY_COLLECTOR_INSTALL");
testCase.otelconfigfile = fullfile(fileparts(mfilename("fullpath")), ...
    "otelcol_config.yml");
testCase.otelroot = getenv("OPENTELEMETRY_MATLAB_INSTALL");
testCase.jsonfile = "myoutput.json";
testCase.pidfile = "testoutput.txt";

% process definitions
testCase.otelcol = fullfile(otelcolroot, "otelcol");
if ispc
   testCase.list = @(name)"tasklist /fi ""IMAGENAME eq " + name + ".exe""";
   testCase.readlist = @(file)readtable(file, "VariableNamingRule", "preserve", "NumHeaderLines", 3, "MultipleDelimsAsOne", true, "Delimiter", " ");
   testCase.extractPid = @(table)table.Var2;
   windows_killroot = string(getenv("WINDOWS_KILL_INSTALL"));
   testCase.sigint = @(id)fullfile(windows_killroot,"windows-kill") + " -SIGINT " + id;
   testCase.sigterm = @(id)"taskkill /pid " + id;
elseif isunix && ~ismac
   testCase.list = @(name)"ps -C " + name;
   testCase.readlist = @readtable;
   testCase.extractPid = @(table)table.PID;
   testCase.sigint = @(id)"kill " + id;  % kill sends a SIGTERM instead of SIGINT but turns out this is sufficient to terminate OTEL collector on Linux
   testCase.sigterm = @(id)"kill " + id;
end

% set up path
addpath(testCase.otelroot);

% remove temporary files if present
if exist(testCase.jsonfile, "file")
    delete(testCase.jsonfile);
end
if exist(testCase.pidfile, "file")
    delete(testCase.pidfile);
end
