# Context Propagation Example

In this example, a C++ client calls a MATLAB function hosted on MATLAB Production Server that returns a magic square matrix. Both the C++ client and the MATLAB code are instrumented with OpenTelemetry, and their generated spans form a single trace.

## Building the Example
1. Enable WITH_EXAMPLES when building OpenTelemetry-Matlab
   ```
   cmake -S . -B build -DWITH_EXAMPLES=ON -DCMAKE_INSTALL_PREFIX=<opentelemetry-matlab-installdir>
   cmake --build build --config Release 
   ```
   The built examples can be found in build/examples/context_propagation and subdirectories.
## Testing the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Test the generated .ctf archive using the [testing interface](https://www.mathworks.com/help/compiler_sdk/mps_dev_test/test-web-request-handler.html) in the Production Server Compiler app.
      1. In MATLAB, cd to the example directory.
         ```
         cd examples/context_propagation/matlab
         ```
      2. Set environment variable PRODSERVER_ROUTES_FILE to point to the routes file.
         ```
         setenv("PRODSERVER_ROUTES_FILE", "routes.json")
         ```
      3. Start Production Server Compiler app.
         ```
         productionServerCompiler
         ```
      4. In the app, select Type as "Deployable Archive (.ctf)", and add mymagic.m as an exported function.
      5. Specify "mymagic" as the archive name.
      6. Click on the "Test Client" button.
      7. Ensure the port is 9910, then start the test.
      8. Start the C++ client from a command prompt.
         ```
         cd build/examples/context_propagation/Release
         contextprop_example_client
         ```
      9. Check for expected spans in the OpenTelemetry Collector or in a specified tracing backend.
## Deploying the Example
1. If testing works, proceed to deploy the example. [Create](https://www.mathworks.com/help/mps/server/creating-a-server.html) and [start](https://www.mathworks.com/help/mps/qs/starting-and-stopping.html) a MATLAB Production Server instance.
2. [Deploy](https://www.mathworks.com/help/mps/qs/share-a-ctf-archive-on-the-server-instance.html) archive mymagic.ctf to server instance by copying to the auto_deploy directory.
3. If using a MATLAB release before R2023b, [copy](https://www.mathworks.com/help/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html) matlab/routes.json to the config directory of the server instance. 
4. Start the C++ client from a command prompt.
   ```
   cd build/examples/context_propagation/Release
   contextprop_example_client
   ```
5. Check for expected spans in the OpenTelemetry Collector or in a specified tracing backend.

**NOTE:** In the first call to MATLAB Production Server, it needs to perform a significant amount of loading and initialization, and as a result the client may time out and return an error status. This should only happen in the first call and not in subsequent calls.
