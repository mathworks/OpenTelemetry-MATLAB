function [response, at] = run_example
% Set up autotracing on the example and run the example. AutoTrace will 
% inject instrumentation code at the beginning of each function to generate 
% one span for each function call.

% Copyright 2026 The MathWorks, Inc.

packagename = "Large Language Models (LLMs) with MATLAB";
installed = matlab.addons.installedAddons;
if ~(ismember(packagename, installed.Name) && matlab.addons.isAddonEnabled(packagename)) && ...
        ~exist("OpenAIChat", "file")
    error("This example requires the """ + packagename + """ add-on. Use the Add-On Explorer to install the add-on.")
end 
runOnce(@initOTel);

% Create AutoTrace object. This will inject instrumentation code at the 
% beginning of each function to generate one span for each function call.
% Exclude internal functions from the trace. 
basedir = fileparts(which("openAIChat"));
excludedirs = ["+internal" "+utils" "+openai"];
excludefiles = ["messageHistory.m" "openAIFunction.m" "openAIImages.m" "openAIMessages.m"];
excludes = [fullfile(basedir, "+llms", excludedirs) fullfile(basedir, excludefiles)];
includes = "roots.m";
at = opentelemetry.autoinstrument.AutoTrace(@InstrumentedAIAgentExample, ...
    ExcludeFiles=excludes, AdditionalFiles=includes, TracerName="LLM_agent_tracing");

% run the example
response = beginTrace(at);
end

function initOTel
% set up global TracerProvider and MeterProvider
resource = dictionary("service.name", "MATLAB_OpenAI_example");
tp = opentelemetry.sdk.trace.TracerProvider(Resource=resource);
setTracerProvider(tp);
mp = opentelemetry.sdk.metrics.MeterProvider(Resource=resource);
setMeterProvider(mp);
end

% This helper ensures the input function is only run once
function runOnce(fh)
persistent hasrun
if isempty(hasrun)
    feval(fh);
    hasrun = 1;
end
end