# Webread Example

In this example, the MATLAB function webread_example calls a C++ server using webread, passing along context information including trace ID and span ID. Both the C++ server and the MATLAB code are instrumented with OpenTelemetry, and their generated spans form a single trace.

## Building the Example
1. Build the C++ server, which requires an installed opentelemetry-cpp package and a vcpkg library manager
   ```
   cd cpp
   cmake -S . -B build -DCMAKE_PREFIX_PATH=<opentelemetry-cpp_install_root>/lib/cmake/opentelemetry-cpp -DCMAKE_TOOLCHAIN_FILE=<vcpkg_root>/scripts/buildsystems/vcpkg.cmake
   cmake --build build --config Release --target <all_target>
   ```
   where <all_target> is "all" on most platforms but is "ALL_BUILD" on Windows with Visual Studio.
2. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
3. Run webread_example in MATLAB.
