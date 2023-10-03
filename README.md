# MATLAB Interface to OpenTelemetry

MATLAB&reg; interface to [OpenTelemetry&trade;](https://opentelemetry.io/), based on the [OpenTelemetry Specification](https://opentelemetry.io/docs/reference/specification/). OpenTelemetry is an observability framework for creating and managing telemetry data, such as traces, metrics, and logs. This data can then be sent to an observability back-end for monitoring, alerts, and analysis. 

### Status
- Currently only tracing is supported. Metrics and logs will be in the future.
- This package is supported and has been tested on Windows&reg;, Linux&reg;, and macOS.

### MathWorks Products (https://www.mathworks.com)

Requires MATLAB release R2022b or newer
- [MATLAB](https://www.mathworks.com/products/matlab.html)

### 3rd Party Products:
- [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector-releases/releases)
- [OpenTelemetry C++](https://github.com/open-telemetry/opentelemetry-cpp)
- [vcpkg C/C++ dependency manager](https://vcpkg.io)

## Installation 
Installation instructions

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
1. Create a default tracer provider and save it.
```
>> p = opentelemetry.sdk.trace.TracerProvider();
>> setTracerProvider(p);
```
2. Start a span
```
>> tr = opentelemetry.trace.getTracer("First Tracer");
>> sp = tr.startSpan("First Span");
```
3. End the span
``` 
>> sp.endSpan();
```
4. If your collector is configured to display the data, you should see your span displayed. 

For more examples, see the "examples" folder.

## Help
To view documentation of individual function, type "help \<function_name>\". For example,
```
>> help opentelemetry.sdk.trace.TracerProvider
```
 
## License
The license is available in the License file within this repository

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2023 The MathWorks, Inc.
