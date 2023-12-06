exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
    "Interval", seconds(100), "Timeout", seconds(1));

mp = opentelemetry.sdk.metrics.MeterProvider(reader); 

view = opentelemetry.sdk.metrics.View(name="mycounter", instrumentName="mycounter", instrumentType="kCounter", meterName="mymeter", meterVersion="1.2.0", meterSchemaURL="", aggregation="kDrop");

addView(mp, view);

m = getMeter(mp, "mymeter", "1.2.0", "");
c = createCounter(m, "mycounter");

% add value and attributes
c.add(10);
c.add(12);
c.add(3);
c.add(6);

pause(2.5);

clear;