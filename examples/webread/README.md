# Webread Example

In this example, the MATLAB function webread_example calls a C++ server using webread, passing along context information including trace ID and span ID. Both the C++ server and the MATLAB code are instrumented with OpenTelemetry, and their generated spans form a single trace.

## Building the Example
1. Enable WITH_EXAMPLES when building OpenTelemetry-Matlab
   ```
   cmake -S . -B build -DWITH_EXAMPLES=ON -DCMAKE_INSTALL_PREFIX=<opentelemetry-matlab-installdir>
   cmake --build build --config Release 
   ```
   The built examples can be found in build/examples/webread and subdirectories.
2. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
3. Run webread_example in MATLAB.
