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
   windows_killroot = getenv("WINDOWS_KILL_INSTALL");
   windows_killname = "windows-kill";
   if isempty(windows_killroot)
       % windows_kill not pre-installed    
       windows_kill_url = "https://github.com/ElyDotDev/windows-kill/releases/download/1.1.4";
       windows_kill_zipfilename = "windows-kill_x64_1.1.4_lib_release";
       windows_killroot = fullfile(tempdir, windows_kill_zipfilename);

       % look for it in tempdir, download and install if it doesn't exist
       if ~exist(fullfile(windows_killroot, windows_killname + ".exe"),"file")
           unzip(fullfile(windows_kill_url, windows_kill_zipfilename + ".zip"), tempdir);
       end       
   end
   testCase.Sigint = @(id)fullfile(windows_killroot,windows_killname) + " -SIGINT " + id;
   testCase.Sigterm = @(id)"taskkill /F /pid " + id;
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
