# OpenTelemetry MATLAB

MATLAB interface to [OpenTelemetry](https://opentelemetry.io/), an observability framework to create and manage telemetry data, such as traces, metrics, and logs. The telemetry data can then be sent to an observability back-end for monitoring and analysis. 

## DISCLAIMERS
**NOTE**: `OpenTelemetry MATLAB`is **UNDER ACTIVE DEVELOPMENT**. It is **NOT** recommended for production use.
- Currently only tracing is supported. Metrics and logs will be in the future.
- This package is supported and has been tested on Windows and Linux. We will add Mac support in the future. 

### MathWorks Products (https://www.mathworks.com)

Requires MATLAB release R2022b or newer
- [MATLAB](https://www.mathworks.com/products/matlab.html)

### 3rd Party Products:
- [Opentelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp)
- [vcpkg C/C++ dependency manager](https://vcpkg.io)

## Installation 
Installation instructions

Before proceeding, ensure that the below products are installed:
* [MATLAB](https://www.mathworks.com/products/matlab.html)

1. Download, build and install [OpenTelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp)
```
cd \<opentelemetry-cpp-root>\
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=20 -DWITH_OTLP=TRUE -DWITH_OTLP_HTTP=TRUE -DWITH_OTLP_GRPC=TRUE -DOPENTELEMETRY_INSTALL=ON -DCMAKE_TOOLCHAIN_FILE=\<vcpkg_toolchain_file>\
cmake --build build --config Release --target ALL_BUILD
cmake --install . --prefix \<opentelemetry-cpp-installdir>\
```
2. Download vcpkg. Install the following packages:
- abseil
- c-ares
- curl
- grpc
- nlohmann-json
- openssl
- protobuf
- re2
- upb
- zlib
- gtest
- benchmark

3. Download OpenTelemetry MATLAB

4. Build and install OpenTelemetry MATLAB
```
cd \<opentelemetry-matlab-root>\
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=\<opentelemetry-matlab-installdir>\ -DCMAKE_TOOLCHAIN_FILE=\<vcpkg_toolchain_file> -DCMAKE_PREFIX_PATH=\<path to opentelemetry-cpp-config.cmake>\
cmake --build build --config Release --target install

```
5. Download [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector-releases/releases). You can just obtain a pre-built binary for your platform.

## Getting Started
1. Start OpenTelemetry Collector
```
otelcol --config \<otelcol-config-yaml>\
```
2. Start MATLAB
3. Add the OpenTelemetry MATLAB install directories to your MATLAB path
```
>> addpath \<OpenTelemetry MATLAB installdir>\
```
## Examples
1. Create a default tracer provider and save it.
```
>> p = opentelemetry.sdk.trace.TracerProvider();
>> setTracerProvider(p);
```
2. Start a span
```
>> tr = opentelemetry.trace.getTracer("First Tracer");
>> sp = startSpan(tr, "First Span");
```
3. End the span
``` 
>> endSpan(sp);
```
4. If your collector is configured to display the data, you should see your span displayed: 
```
2023-03-21T11:29:44.570-0400    info    TracesExporter  {"kind": "exporter", "data_type": "traces", "name": "logging", "#spans": 1}
2023-03-21T11:29:55.525-0400    info    ResourceSpans #0
Resource SchemaURL:
Resource attributes:
     -> telemetry.sdk.language: STRING(MATLAB)
     -> telemetry.sdk.name: STRING(opentelemetry)
     -> telemetry.sdk.version: STRING(0.1.0)
     -> service.name: STRING(unknown_service)
ScopeSpans #0
ScopeSpans SchemaURL:
InstrumentationScope First Tracer
Span #0
    Trace ID       : 2a298501841ef6e2f73fbef5a9245e5e
    Parent ID      :
    ID             : fccba2f9e2262bd5
    Name           : First Span
    Kind           : SPAN_KIND_INTERNAL
    Start time     : 2023-03-21 15:29:39.8057461 +0000 UTC
    End time       : 2023-03-21 15:29:44.4545706 +0000 UTC
    Status code    : STATUS_CODE_UNSET
    Status message :
        {"kind": "exporter", "data_type": "traces", "name": "logging"}
```

## License
The license is available in the License file within this repository

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2023 The MathWorks, Inc.
