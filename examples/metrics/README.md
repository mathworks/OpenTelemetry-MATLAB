# Metrics Example
There are two examples in this directory, metrics\_example and async\_metrics\_example.

## metrics\_example
This example shows how to emit OpenTelemetry synchronous metrics from MATLAB. It uses all 3 synchronous instruments counter, updowncounter, and histogram.
* At the beginning of the first run, initialization is necessary to create and store a global meter provider.
* The example then enters a loop and at each iteration updates all 3 instruments. The metrics will then be exported periodically at a fixed time interval.

## async\_metrics\_example
This example shows how to emit OpenTelemetry asynchronous metrics from MATLAB. Is uses all 3 asynchronous instruments observable counter, observable
updowncounter, and obervable gauge.
* Initialization is first done by creating and storing a global meter provider, and specifying a data export interval and timeout.
* The asynchronous instruments are then created, passing in their respective callback functions.
* The example then pauses for 100 seconds, allowing the asynchronous instruments to periodically fetch and export their measurements.
* Finally, the global meter provider is shut down to stop any further data exports.

## Running the Examples
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Start MATLAB. 
3. Ensure the installation directory of OpenTelemetry-matlab is on the MATLAB path.
4. Run metrics\_example or async\_metrics\_example.
