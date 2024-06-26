classdef async_metrics_example_callbacks < handle
    % Callback functions for asynchronous metrics example

    % Copyright 2024 The MathWorks, Inc.

    properties
        Count
        UpDownCount
    end

    methods
        function obj = async_metrics_example_callbacks()
            obj.Count = 0;
            obj.UpDownCount = 0;
        end

        function result = counterCallback(obj)
            % Callback function for Counter
            obj.Count = obj.Count + randi(10); % increment between 0 and 10
            result = opentelemetry.metrics.ObservableResult;
            result = result.observe(obj.Count);
        end

        function result = updowncounterCallback(obj)
            % Callback function for UpdownCounter
            obj.UpDownCount = obj.UpDownCount + randi([-5 5]); % increment between -5 to 5
            result = opentelemetry.metrics.ObservableResult;
            result = result.observe(obj.UpDownCount);
        end

        function result = gaugeCallback(~)
            % Callback function for Gauge
            s = second(datetime("now"));    % get the current second of the minute
            result = opentelemetry.metrics.ObservableResult;
            result = result.observe(s);
        end
    end
end
