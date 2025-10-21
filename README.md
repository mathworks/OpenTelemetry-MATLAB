# MATLAB Interface to OpenTelemetry
[![View OpenTelemetry-Matlab on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/130979-opentelemetry-matlab) [![MATLAB](https://github.com/mathworks/OpenTelemetry-Matlab/actions/workflows/build_and_test_full.yml/badge.svg)](https://github.com/mathworks/OpenTelemetry-Matlab/actions/workflows/build_and_test_full.yml)[![codecov](https://codecov.io/github/mathworks/OpenTelemetry-MATLAB/graph/badge.svg?token=VNj6f1LlMG)](https://codecov.io/github/mathworks/OpenTelemetry-MATLAB)

MATLAB&reg; interface to [OpenTelemetry&trade;](https://opentelemetry.io/), based on the [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/). OpenTelemetry is an observability framework for creating and managing telemetry data, such as traces, metrics, and logs. This data can then be sent to an observability back-end for monitoring, alerts, and analysis. 

### Status
1. Tracing, metrics, and logs are all fully supported and tested on Windows&reg;, Linux&reg;, and macOS.
2. On Linux, when running MATLAB R2025a or newer releases, the gRPC library used in the gRPC exporter in this package may conflict with the same library in MATLAB, causing MATLAB to crash. To avoid this issue, install otel-matlab-nogrpc.mltbx in [version 1.10.2](https://github.com/mathworks/OpenTelemetry-MATLAB/releases/tag/1.10.2), which excludes the gRPC exporter.
3. OpenTelemetry currently does not support non-ASCII characters. Defining names or attributes with non-ASCII characters will cause the telemetry data to become invalid and fail to export.

### MathWorks Products (https://www.mathworks.com)

Requires MATLAB release R2022b or newer
- [MATLAB](https://www.mathworks.com/products/matlab.html)

### 3rd Party Products:
- [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector-releases/releases)
- [OpenTelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp)
- [vcpkg C/C++ dependency manager](https://vcpkg.io)

## Installation 
Installation instructions

### Installing With Toolbox Package
1. Under "Assets" of a release, download the toolbox package .mltbx file.
2. Start MATLAB.
3. In the Current Folder browser, navigate to the .mltbx file.
4. Right click on the .mltbx file and select "Install".

### Building From Source
Before proceeding, ensure that the below products are installed:
* [MATLAB](https://www.mathworks.com/products/matlab.html)

1. Download, Build and install OpenTelemetry MATLAB
```
cd <opentelemetry-matlab-root>
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=<opentelemetry-matlab-installdir>
cmake --build build --config Release --target install

```
2. Download [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector-releases/releases). You can just obtain a pre-built binary for your platform.

## Getting Started
1. Start OpenTelemetry Collector
```
otelcol --config <otelcol-config-yaml>
```
2. Start MATLAB
3. Add the OpenTelemetry MATLAB install directories to your MATLAB path
```
>> addpath <OpenTelemetry MATLAB installdir>
```
## Examples
### Tracing
1. Create a default tracer provider and save it.
```
>> p = opentelemetry.sdk.trace.TracerProvider();
>> setTracerProvider(p);
```
2. Start a span
```
>> tr = opentelemetry.trace.getTracer("My Tracer");
>> sp = tr.startSpan("My Span");
```
3. End the span
``` 
>> sp.endSpan();
```
4. If your collector is configured to display the data, you should see your span displayed. 
### Metrics
1. Create a default meter provider and save it.
```
>> p = opentelemetry.sdk.metrics.MeterProvider();
>> setMeterProvider(p);
```
2. Create a counter
```
>> m = opentelemetry.metrics.getMeter("My Meter");
>> c = m.createCounter("My Counter");
```
3. Increment the counter
```
>> c.add(10);
```
4. If your collector is configured to display the data, you should see your counter displayed after 1 minute.

### Logs
1. Create a default logger provider and save it.
```
>> p = opentelemetry.sdk.logs.LoggerProvider();
>> setLoggerProvider(p);
```
2. Create a logger
```
>> l = opentelemetry.logs.getLogger("My Logger");
```
3. Emit a log record with "info" level
```
>> info(l, "My Message");
```
4. If your collector is configured to display the data, you should see your log record displayed.

For more examples, see the "examples" folder.

## Automatic Instrumentation
See example [here](auto-instrumentation/README.md).

## Help
To view documentation of individual function, type "help \<function_name>\". For example,
```
>> help opentelemetry.sdk.trace.TracerProvider
```
 
## License
The license is available in the License file within this repository

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2023-2024 The MathWorks, Inc.
