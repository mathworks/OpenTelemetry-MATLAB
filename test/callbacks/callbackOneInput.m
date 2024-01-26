function result = callbackOneInput(addvalue)
% Test callback function for asynchronous instruments
%
% Copyright 2024 The MathWorks, Inc.

value = 5 + addvalue;
result = opentelemetry.metrics.ObservableResult;
result = result.observe(value);