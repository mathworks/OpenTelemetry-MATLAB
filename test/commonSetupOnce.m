function commonSetupOnce(testCase)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

% file definitions
otelcolroot = getenv("OPENTELEMETRY_COLLECTOR_INSTALL");
assert(~isempty(otelcolroot), "OPENTELEMETRY_COLLECTOR_INSTALL environment must be defined.")
testCase.OtelConfigFile = fullfile(fileparts(mfilename("fullpath")), ...
    "otelcol_config.yml");
otelroot = getenv("OPENTELEMETRY_MATLAB_INSTALL");
assert(~isempty(otelroot), "OPENTELEMETRY_MATLAB_INSTALL environment must be defined.")
testCase.OtelRoot = otelroot;
testCase.JsonFile = "myoutput.json";
testCase.PidFile = "testoutput.txt";

% process definitions
testCase.OtelcolName = "otelcol";
if ispc
   testCase.ListPid = @(name)"tasklist /fi ""IMAGENAME eq " + name + ".exe""";
   testCase.ReadPidList = @(file)readtable(file, "VariableNamingRule", "preserve", "NumHeaderLines", 3, "MultipleDelimsAsOne", true, "Delimiter", " ");
   testCase.ExtractPid = @(table)table.Var2;
   windows_killroot = string(getenv("WINDOWS_KILL_INSTALL"));
   assert(~isempty(windows_killroot), "WINDOWS_KILL_INSTALL environment must be defined.")
   testCase.Sigint = @(id)fullfile(windows_killroot,"windows-kill") + " -SIGINT " + id;
   testCase.Sigterm = @(id)"taskkill /pid " + id;
elseif isunix && ~ismac
   testCase.ListPid = @(name)"ps -C " + name;
   testCase.ReadPidList = @readtable;
   testCase.ExtractPid = @(table)table.PID;
   testCase.Sigint = @(id)"kill " + id;  % kill sends a SIGTERM instead of SIGINT but turns out this is sufficient to terminate OTEL collector on Linux
   testCase.Sigterm = @(id)"kill " + id;
elseif ismac
   testCase.ListPid = @(name)"pgrep -x " + name;
   testCase.ReadPidList = @readmatrix;
   testCase.ExtractPid = @(x)x;  % no-op that returns itself
   testCase.Sigint = @(id)"kill -s INT " + id;  
   testCase.Sigterm = @(id)"kill -s TERM " + id;
   if computer == "MACA64"
      % only the contrib version of OpenTelemetry Collector is available on Apple silicon
      testCase.OtelcolName = "otelcol-contrib";
   end

end
testCase.Otelcol = fullfile(otelcolroot, testCase.OtelcolName);

% set up path
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(testCase.OtelRoot));

% remove temporary files if present
if exist(testCase.JsonFile, "file")
    delete(testCase.JsonFile);
end
if exist(testCase.PidFile, "file")
    delete(testCase.PidFile);
end
