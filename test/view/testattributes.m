exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
    "Interval", seconds(2), "Timeout", seconds(1));

mp = opentelemetry.sdk.metrics.MeterProvider(reader); 

view = opentelemetry.sdk.metrics.View(name="View", description="my View", instrumentName="mycounter", instrumentType="kCounter", meterName="mymeter", attributeKeys="Group", aggregation="kSum");

addView(mp, view);

m = getMeter(mp, "mymeter");
c = createCounter(m, "mycounter");


% add value and attributes
c.add(3, "Group", "A", "Trial", 1);
c.add(1, "Group", "A", "Trial", 2);
c.add(12, "Group", "A", "Trial", 1);
c.add(7, "Group", "A", "Trial", 2);

% wait for collector response time (2s)
pause(5);

clear;