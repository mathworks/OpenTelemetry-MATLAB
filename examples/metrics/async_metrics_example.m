function async_metrics_example(iterations)
% This example creates 3 asynchronous metric instruments including an 
% observable counter, an observable updowncounter, and an observable gauge. 

% Copyright 2024 The MathWorks, Inc.

if nargin < 1
    iterations = 20;    % default to 20 iterations
end

% initialize meter provider
initMetrics;

% create meter and instruments
m = opentelemetry.metrics.getMeter("async_metrics_example");
callbacks = async_metrics_example_callbacks;
c = createObservableCounter(m, @()counterCallback(callbacks), "observable_counter"); %#ok<*NASGU>
u = createObservableUpDownCounter(m, @()updowncounterCallback(callbacks), "observable_updowncounter");
g = createObservableGauge(m, @()gaugeCallback(callbacks), "observable_gauge"); 
pause(iterations*5);

% clean up
cleanupMetrics;
end


function initMetrics
% set up global MeterProvider
exp = opentelemetry.exporters.otlp.defaultMetricExporter();
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exp, ...
    "Interval", seconds(5), "Timeout", seconds(2.5));  % exports every 5 seconds
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
mp = opentelemetry.sdk.metrics.MeterProvider(reader, Resource=resource);
setMeterProvider(mp);
end

function cleanupMetrics
% clean up meter provider
mp = opentelemetry.metrics.Provider.getMeterProvider();
opentelemetry.sdk.common.Cleanup.shutdown(mp);   % shutdown
end