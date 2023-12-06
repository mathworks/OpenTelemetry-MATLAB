exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                            "Interval", seconds(2), "Timeout", seconds(1));
mp = opentelemetry.sdk.metrics.MeterProvider(reader);

view = opentelemetry.sdk.metrics.View(Name="View", Description="my View", InstrumentName="histogram", InstrumentType="kHistogram", MeterName="mymeter", Aggregation="kHistogram", HistogramBinEdges=[0 100 200 300 400 500]);

addView(mp, view);

m = mp.getMeter("mymeter");
hist = m.createHistogram("histogram");

% record values
hist.record(1);
hist.record(200);
hist.record(201);
hist.record(400);
hist.record(401);

% wait for collector response
pause(2.5);


clear;