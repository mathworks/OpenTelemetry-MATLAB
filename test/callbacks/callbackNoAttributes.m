function result = callbackNoAttributes()
% Test callback function for asynchronous instruments
%
% Copyright 2024 The MathWorks, Inc.

value = 5;
result = opentelemetry.metrics.ObservableResult;
result = result.observe(value);