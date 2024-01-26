function result = callbackWithAttributes2()
% Test callback function for asynchronous instruments that uses attributes
%
% Copyright 2024 The MathWorks, Inc.

value = 20;
result = opentelemetry.metrics.ObservableResult;
result = result.observe(value, "Level", "C");