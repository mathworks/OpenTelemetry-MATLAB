# Logs Example
This example shows how to emit logs in MATLAB code using OpenTelemetry. OpenTelemetry-Matlab supports logging either through its front-end API, or using existing logging functions together with an appender. This example shows logging through front-end API. Currently, there is not yet any appenders available in the package.
* At the beginning of the first run, initialization is necessary to create and store a global logger provider.
* At the beginning of each function, the global logger provider is used to create a logger.
* Use the created logger to create and emit logs.

## Running the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Start MATLAB. 
3. Ensure the installation directory of OpenTelemetry-matlab is on the MATLAB path.
4. Run logs_example.
