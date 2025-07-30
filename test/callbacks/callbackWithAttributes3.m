function result = callbackWithAttributes3()
% Test callback function for asynchronous instruments that uses attributes
%
% Copyright 2024 The MathWorks, Inc.

value = 30;
result = opentelemetry.metrics.ObservableResult;
result = result.observe(value, dictionary({"Level1"}, {"D"},{"Level2"},{"E"}));