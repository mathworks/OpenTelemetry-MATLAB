function commonSetupOnce(testCase)
% Setup function for tests
%
% Copyright 2023 The MathWorks, Inc.

% file definitions
otelcolroot = getenv("OPENTELEMETRY_COLLECTOR_INSTALL");
testCase.OtelConfigFile = fullfile(fileparts(mfilename("fullpath")), ...
    "otelcol_config.yml");
otelroot = getenv("OPENTELEMETRY_MATLAB_INSTALL");
testCase.JsonFile = "myoutput.json";
testCase.PidFile = "testoutput.txt";

% process definitions
if ispc
   testCase.ListPid = @(name)"tasklist /fi ""IMAGENAME eq " + name + ".exe""";
   testCase.ReadPidList = @(file)readtable(file, "VariableNamingRule", "preserve", "NumHeaderLines", 3, "MultipleDelimsAsOne", true, "Delimiter", " ");
   testCase.ExtractPid = @(table)table.Var2;   
   
   % variables to support downloading OpenTelemetry Collector
   otelcol_arch_name = "windows_amd64";
   otelcol_exe_ext = ".exe";

   % windows_kill
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

   % variables to support downloading OpenTelemetry Collector
   otelcol_arch_name = "linux_amd64";
   otelcol_exe_ext = "";
elseif ismac
   testCase.ListPid = @(name)"pgrep -x " + name;
   testCase.ReadPidList = @readmatrix;
   testCase.ExtractPid = @(x)x;  % no-op that returns itself
   testCase.Sigint = @(id)"kill -s INT " + id;  
   testCase.Sigterm = @(id)"kill -s TERM " + id;
   if computer == "MACA64"
      otelcol_arch_name = "darwin_arm64";
   else
      otelcol_arch_name = "darwin_amd64";
   end
   otelcol_exe_ext = "";

end

% OpenTelemetry Collector
otelcolname = "otelcol";
if isempty(otelcolroot)
    % collector not pre-installed
    otelcol_version = "0.85.0";
    otelcol_url = "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v" ...
        + otelcol_version;
    otelcol_zipfilename = "otelcol_" + otelcol_version + "_" + otelcol_arch_name;
    otelcolroot = fullfile(tempdir, otelcol_zipfilename);

    % look for it in tempdir, download and install if it doesn't exist
    if ~(exist(fullfile(otelcolroot, otelcolname + otelcol_exe_ext),"file") || ...
            exist(fullfile(otelcolroot,otelcolname + "-contrib" + otelcol_exe_ext),"file"))
        % download and install
        otelcol_tar = gunzip(fullfile(otelcol_url, otelcol_zipfilename + ".tar.gz"), otelcolroot);
        otelcol_tar = otelcol_tar{1}; % should have only extracted 1 tar file
        untar(otelcol_tar, otelcolroot);
        delete(otelcol_tar);
    end
end
% check for contrib version
if exist(fullfile(otelcolroot,otelcolname + "-contrib" + otelcol_exe_ext),"file")
    testCase.OtelcolName = otelcolname + "-contrib";
else
    testCase.OtelcolName = otelcolname;
end

testCase.Otelcol = fullfile(otelcolroot, testCase.OtelcolName);

% set up path
if ~isempty(otelroot)
    testCase.applyFixture(matlab.unittest.fixtures.PathFixture(otelroot));
end

% remove temporary files if present
if exist(testCase.JsonFile, "file")
    delete(testCase.JsonFile);
end
if exist(testCase.PidFile, "file")
    delete(testCase.PidFile);
end
