# Trace Example
This example shows how to instrument simple MATLAB code using spans. The instrumented code is a function that fits a line through a cluster of data points. 
* At the beginning of the first run, initialization is necessary to create and store a global tracer provider.
* At the beginning of each function, the global tracer provider is used to create a tracer.
* Use the created tracer to start a span.
* Make the new span the current span. Spans subsequently started will be children of this span.

## Running the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Start MATLAB. 
3. Ensure the installation directory of OpenTelemetry-matlab is on the MATLAB path.
4. Run trace_example.
