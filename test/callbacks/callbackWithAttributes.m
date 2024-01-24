function result = callbackWithAttributes()
% Test callback function for asynchronous instruments that uses attributes
%
% Copyright 2024 The MathWorks, Inc.

value1 = 5;
value2 = 10;
result = opentelemetry.metrics.ObservableResult;
result = result.observe(value1, "Level", "A");
result = result.observe(value2, "Level", "B");