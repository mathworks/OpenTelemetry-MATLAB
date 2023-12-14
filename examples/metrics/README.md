# Metrics Example
This example shows how to emit OpenTelemetry metrics from MATLAB. It uses all 3 synchronous instruments counter, updowncounter, and histogram.
* At the beginning of the first run, initialization is necessary to create and store a global meter provider.
* The example then enters a loop and at each iteration updates all 3 instruments. The metrics will then be exported periodically at a fixed time interval.

## Running the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Start MATLAB. 
3. Ensure the installation directory of OpenTelemetry-matlab is on the MATLAB path.
4. Run metrics_example.
