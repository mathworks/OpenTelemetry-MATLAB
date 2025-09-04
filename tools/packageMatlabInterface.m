% packageMatlabInterface.m
% This script packages installed files for OpenTelemetry interface and
% package them into a single .mltbx file. The location of the installed
% files is taken from environment variable OTEL_MATLAB_TOOLBOX_FOLDER and
% the resulting .mltbx file location is taken from environment variable
% OTEL_MATLAB_TOOLBOX_OUTPUT_FOLDER.

% Copyright 2024 The MathWorks, Inc.

toolboxFolder = string(getenv("OTEL_MATLAB_TOOLBOX_FOLDER"));
outputFolder = string(getenv("OTEL_MATLAB_TOOLBOX_OUTPUT_FOLDER"));
toolboxVersion = string(getenv("OTEL_MATLAB_TOOLBOX_VERSION"));
workingFolder = string(getenv("WORKING_FOLDER"));
toolboxName = string(getenv("OTEL_MATLAB_TOOLBOX_NAME"));

% cd to working folder
cd(workingFolder);

% Output folder must exist.
mkdir(outputFolder);

disp("Toolbox Folder: " + toolboxFolder);
disp("Output Folder: " + outputFolder);
disp("Toolbox Version:" + toolboxVersion);
disp("Toolbox Name:" + toolboxName);

identifier = "dc2cae2f-4f43-4d2c-b6ed-f1a59f0dfcdf";
opts = matlab.addons.toolbox.ToolboxOptions(toolboxFolder, identifier);
opts.ToolboxName = "MATLAB Interface to OpenTelemetry";
opts.ToolboxVersion = toolboxVersion;
opts.AuthorName = "MathWorks DevOps Team";
opts.AuthorEmail = "";

% Set the SupportedPlatforms
opts.SupportedPlatforms.Win64 = true;
opts.SupportedPlatforms.Maci64 = true;
opts.SupportedPlatforms.Glnxa64 = true;
opts.SupportedPlatforms.MatlabOnline = true;

opts.MinimumMatlabRelease = "R2022a";

opts.OutputFile = fullfile(outputFolder, toolboxName + ".mltbx");
disp("Output File: " + opts.OutputFile);
matlab.addons.toolbox.packageToolbox(opts);
