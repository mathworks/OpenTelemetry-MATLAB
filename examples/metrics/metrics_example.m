function metrics_example
% This example creates 3 metric instruments including a counter, an 
% updowncounter, and a histogram. It then enters a loop and updates the 
% value of the instruments at each iteration.

% Copyright 2023 The MathWorks, Inc.

% initialize meter provider during first run
runOnce(@initMetrics);

% create meter and instruments
m = opentelemetry.metrics.getMeter("metrics_example");
c = createCounter(m, "counter");
u = createUpDownCounter(m, "updowncounter");
h = createHistogram(m, "histogram");
iterations = 20;    % number of iterations

for i = 1:iterations
    c.add(randi(10));
    u.add(randi([-10 10]));
    h.record(50 + 15*randn);  % normal distribution with mean 50 and std 15
    pause(5);
end
end


function initMetrics
% set up global MeterProvider
exp = opentelemetry.exporters.otlp.defaultMetricExporter();
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exp, ...
    "Interval", seconds(5), "Timeout", seconds(2.5));  % exports every 5 seconds
% Use custom histogram bins
v = opentelemetry.sdk.metrics.View(InstrumentType="histogram", HistogramBinEdges=0:10:100);
mp = opentelemetry.sdk.metrics.MeterProvider(reader, View=v);
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
