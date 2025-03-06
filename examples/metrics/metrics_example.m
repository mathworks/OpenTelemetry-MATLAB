function metrics_example(iterations)
% This example creates 4 metric instruments including a counter, an 
% updowncounter, a histogram, and a gauge. It then enters a loop and updates 
% the value of the instruments at each iteration.

% Copyright 2023-2025 The MathWorks, Inc.

if nargin < 1
    iterations = 20;    % default to 20 iterations
end

% initialize meter provider
initMetrics;

% create meter and instruments
m = opentelemetry.metrics.getMeter("metrics_example");
c = createCounter(m, "counter");
u = createUpDownCounter(m, "updowncounter");
h = createHistogram(m, "histogram");
g = createGauge(m, "gauge");

% wait a little before starting
pause(2);
for i = 1:iterations
    c.add(randi(10));         % integer between 1 and 10
    u.add(randi([-10 10]));   % integer between -10 and 10
    h.record(50 + 15*randn);  % normal distribution with mean 50 and std 15
    g.record(100*rand);       % real number between 0 and 100
    pause(5);
end

% clean up
cleanupMetrics;
end


function initMetrics
% set up global MeterProvider
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(...
    "Interval", seconds(5), "Timeout", seconds(2.5));  % exports every 5 seconds
% Use custom histogram bins
v = opentelemetry.sdk.metrics.View(InstrumentType="histogram", HistogramBinEdges=0:10:100);
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
mp = opentelemetry.sdk.metrics.MeterProvider(reader, View=v, ...
    Resource=resource);
setMeterProvider(mp);
end

function cleanupMetrics
mp = opentelemetry.metrics.Provider.getMeterProvider();
opentelemetry.sdk.common.Cleanup.shutdown(mp);   % shutdown
end

