# AutoTrace Example
This example shows how to use AutoTrace to automatically instrument MATLAB code. The instrumented code in *autotrace_example.m* fits a line through a cluster of data points. Notice that it does not include any instrumentation code. 
The function *run_example.m* first configures a tracer provider. This step only needs to be done once in a MATLAB session. Then it creates an AutoTrace object and runs it. The AutoTrace object gets cleaned up at the end. 

## Running the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Start MATLAB. 
3. Ensure the installation directory of OpenTelemetry-matlab is on the MATLAB path.
4. Run `run_example`.
