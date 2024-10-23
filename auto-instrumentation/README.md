# Automatic Instrumentation

Automatic instrumentation provides a way to instrument MATLAB code with OpenTelemetry data without requiring any code changes.

## AutoTrace
With AutoTrace enabled, spans are automatically started at function beginnings and ended when functions end. By default, AutoTrace instruments the input function and all of its dependencies. An example workflow is as follows:  
```
% The example functions should be on the path when calling AutoTrace
addpath("myexample");

% Configure a tracer provider and set it as the global instance
tp = opentelemetry.sdk.trace.TracerProvider;   % use default settings
setTracerProvider(tp);

% Instrument the code
at = opentelemetry.autoinstrument.AutoTrace(@myexample, TracerName="AutoTraceExample");

% Start the example
beginTrace(at);
```
Using the `beginTrace` method ensures proper error handling. In the case of an error, `beginTrace` will end all spans and set the "Error" status.

Alternatively, you can also get the same behavior by inserting a try-catch in the starting function.
```
function myexample(at)
% wrap a try catch around the code
try
    % example code goes here
catch ME
    handleError(at);
end
```
With the try-catch, `beginTrace` method is no longer necessary and you can simply call `myexample` directly and pass in the AutoTrace object.

To disable automatic tracing, delete the object returned by `AutoTrace`. 
