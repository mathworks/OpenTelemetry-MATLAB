exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
    "Interval", seconds(2), "Timeout", seconds(1));
mp = opentelemetry.sdk.metrics.MeterProvider(reader); 

view = opentelemetry.sdk.metrics.View(name="View", description="my View", instrumentName="mycounter", instrumentType="kUpDownCounter", meterName="mymeter", aggregation="kLastValue");

addView(mp, view);

m = getMeter(mp, "mymeter");
c = createUpDownCounter(m, "mycounter");


% add value and attributes
c.add(-10);
c.add(-5);
c.add(12);
c.add(7);

% wait for collector response time (2s)
pause(5);

clear;