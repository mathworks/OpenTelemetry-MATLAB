# Context Propagation Example

In this example, a C++ client calls a MATLAB function hosted on MATLAB Production Server that returns a magic square matrix. Both the C++ client and the MATLAB code are instrumented with OpenTelemetry, and their generated spans form a single trace.

## Building the Example
1. Build the C++ client, which requires an installed opentelemetry-cpp package and a vcpkg library manager
   ```
   cd cpp
   cmake -S . -B build -DCMAKE_PREFIX_PATH=<opentelemetry-cpp_install_root>/lib/cmake/opentelemetry-cpp -DCMAKE_TOOLCHAIN_FILE=<vcpkg_root>/scripts/buildsystems/vcpkg.cmake
   cmake --build build --config Release --target <all_target>
   ```
   where <all_target> is "all" on most platforms but is "ALL_BUILD" on Windows with Visual Studio.
2. Build MATLAB code into a deployable archive. Use the following MATLAB command:
   ```
   cd matlab
   mcc -W CTF:mymagic -U mymagic.m  -a <opentelemetry-cpp_install_root> -a <opentelemetry-cpp_install_root>\+libmexclass\+proxy
   ```
3. [Create](https://www.mathworks.com/help/mps/server/creating-a-server.html) and [start](https://www.mathworks.com/help/mps/qs/starting-and-stopping.html) a MATLAB Production Server instance.
4. [Deploy](https://www.mathworks.com/help/mps/qs/share-a-ctf-archive-on-the-server-instance.html) archive to server instance by copying to the auto_deploy directory.
5. [Copy](https://www.mathworks.com/help/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html) matlab/routes.json to the config directory of the server instance.
6. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
7. Start the C++ client.
   ```
   cd cpp/build/Release
   http_client
   ```
