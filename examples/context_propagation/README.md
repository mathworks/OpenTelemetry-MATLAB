# Context Propagation Example

In this example, a C++ client calls a MATLAB function hosted on MATLAB Production Server that returns a magic square matrix. Both the C++ client and the MATLAB code are instrumented with OpenTelemetry, and their generated spans form a single trace.

## Building the Example
1. Enable WITH_EXAMPLES when building OpenTelemetry-Matlab
   ```
   cmake -S . -B build -DWITH_EXAMPLES=ON -DCMAKE_INSTALL_PREFIX=<opentelemetry-matlab-installdir>
   cmake --build build --config Release 
   ```
   The built examples can be found in build/examples/context_propagation and subdirectories.
2. [Create](https://www.mathworks.com/help/mps/server/creating-a-server.html) and [start](https://www.mathworks.com/help/mps/qs/starting-and-stopping.html) a MATLAB Production Server instance.
3. [Deploy](https://www.mathworks.com/help/mps/qs/share-a-ctf-archive-on-the-server-instance.html) archive to server instance by copying to the auto_deploy directory.
4. If using a MATLAB release before R2023b, [copy](https://www.mathworks.com/help/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html) matlab/routes.json to the config directory of the server instance. 
6. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
7. Start the C++ client.
   ```
   cd cpp/build/Release
   http_client
   ```
