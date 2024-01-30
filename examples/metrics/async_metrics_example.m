function async_metrics_example
% This example creates 3 asynchronous metric instruments including an 
% observable counter, an observable updowncounter, and an observable gauge. 

% Copyright 2024 The MathWorks, Inc.

% initialize meter provider
initMetrics;

% create meter and instruments
m = opentelemetry.metrics.getMeter("async_metrics_example");
c = createObservableCounter(m, @counter_callback, "observable_counter"); %#ok<*NASGU>
u = createObservableUpDownCounter(m, @updowncounter_callback, "observable_updowncounter");
g = createObservableGauge(m, @gauge_callback, "observable_gauge"); 
iterations = 20;    % number of iterations
pause(iterations*5);

% clean up
cleanupMetrics;
end


function initMetrics
% set up global MeterProvider
exp = opentelemetry.exporters.otlp.defaultMetricExporter();
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exp, ...
    "Interval", seconds(5), "Timeout", seconds(2.5));  % exports every 5 seconds
mp = opentelemetry.sdk.metrics.MeterProvider(reader);
setMeterProvider(mp);
end

function cleanupMetrics
mp = opentelemetry.metrics.Provider.getMeterProvider();
opentelemetry.sdk.common.Cleanup.shutdown(mp);   % shutdown
end

function result = counter_callback()
persistent value
if isempty(value)
    value = 0;
else
    value = value + randi(10);  % increment between 1 to 10
end
result = opentelemetry.metrics.ObservableResult;
result = result.observe(value);
end

function result = updowncounter_callback()
persistent value
if isempty(value)
    value = 0;
else
    value = value + randi([-5 5]);  % increment between -5 to 5
end
result = opentelemetry.metrics.ObservableResult;
result = result.observe(value);
end

function result = gauge_callback()
s = second(datetime("now"));    % get the current second of the minute
result = opentelemetry.metrics.ObservableResult;
result = result.observe(s);
end