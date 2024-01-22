classdef Meter < handle
    % A Meter creates metric instruments, capturing measurements about a service at runtime. 
    % Meters are created from Meter Providers.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name    (1,1) string   % Meter name
        Version (1,1) string   % Meter version
        Schema  (1,1) string   % URL that documents the schema of the generated spans
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.sdk.metrics.MeterProvider, ?opentelemetry.metrics.MeterProvider})

        function obj = Meter(proxy, mtname, mtversion, mtschema)
            % Private constructor. Use getMeter method of MeterProvider
            % to create Meters.
            obj.Proxy = proxy;
            obj.Name = mtname;
            obj.Version = mtversion;
            obj.Schema = mtschema;
        end

    end

    methods
    
        function counter = createCounter(obj, name, description, unit)
            % CREATECOUNTER Create a counter
            %    C = CREATECOUNTER(M, NAME) creates a counter with the specified
            %    name. A counter's value can only increase but not
            %    decrease.
            %
            %    C = CREATECOUNTER(M, NAME, DESCRIPTION, UNIT) also 
            %    specifies a description and a unit.
            %     
            %    See also CREATEUPDOWNCOUNTER, CREATEHISTOGRAM,
            %    CREATEOBSERVABLECOUNTER
            arguments
                obj
                name
                description = ""
                unit = ""
            end
            [name, description, unit] = processSynchronousInputs(name, ...
                description, unit);
            id = obj.Proxy.createCounter(name, description, unit);
            CounterProxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.CounterProxy", "ID", id);
            counter = opentelemetry.metrics.Counter(CounterProxy, name, description, unit);
        end


        function updowncounter = createUpDownCounter(obj, name, description, unit)
            % CREATEUPDOWNCOUNTER Create an UpDownCounter
            %    C = CREATEUPDOWNCOUNTER(M, NAME) creates an UpDownCounter 
            %    with the specified name. An UpDownCounter's value can
            %    increase or decrease.
            %
            %    C = CREATEUPDOWNCOUNTER(M, NAME, DESCRIPTION, UNIT) also 
            %    specifies a description and a unit.
            %     
            %    See also CREATECOUNTER, CREATEHISTOGRAM,
            %    CREATEOBSERVABLEUPDOWNCOUNTER
            arguments
                obj
                name
                description = ""
                unit = ""
            end

            [name, description, unit] = processSynchronousInputs(name, ...
                description, unit);
            id = obj.Proxy.createUpDownCounter(name, description, unit);
            UpDownCounterProxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.UpDownCounterProxy", "ID", id);
            updowncounter = opentelemetry.metrics.UpDownCounter(UpDownCounterProxy, name, description, unit);
        end


        function histogram = createHistogram(obj, name, description, unit)
            % CREATEHISTOGRAM Create a histogram
            %    H = CREATEHISTOGRAM(M, NAME) creates a histogram with the specified
            %    name. A histogram aggregates values into bins. Bins can be
            %    customized using a View object.
            %
            %    H = CREATEHISTOGRAM(M, NAME, DESCRIPTION, UNIT) also 
            %    specifies a description and a unit.
            %     
            %    See also CREATECOUNTER, CREATEUPDOWNCOUNTER,
            %    OPENTELEMETRY.SDK.METRICS.VIEW
            arguments
                obj
                name
                description = ""
                unit = ""
            end

            [name, description, unit] = processSynchronousInputs(name, ...
                description, unit);
            id = obj.Proxy.createHistogram(name, description, unit);
            HistogramProxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.HistogramProxy", "ID", id);
            histogram = opentelemetry.metrics.Histogram(HistogramProxy, name, description, unit);
        end

    	function obscounter = createObservableCounter(obj, callback, name, description, unit)
            % CREATEOBSERVABLECOUNTER Create an observable counter
            %    C = CREATEOBSERVABLECOUNTER(M, CALLBACK, NAME) creates an 
            %    observable counter with the specified callback function 
            %    and name. The callback function, specified as a 
            %    function handle, must accept no input and return one
            %    output of type opentelemetry.metrics.ObservableResult.
            %    The counter's value can only increase but not decrease.
            %
            %    C = CREATEOBSERVABLECOUNTER(M, CALLBACK NAME, DESCRIPTION, UNIT) 
            %    also specifies a description and a unit.
            %     
            %    See also OPENTELEMETRY.METRICS.OBSERVABLERESULT, 
            %    CREATEOBSERVABLEUPDOWNCOUNTER, CREATEOBSERVABLEGAUGE, CREATECOUNTER
            arguments
                obj
                callback
                name
                description = ""
                unit = ""
            end

            [callback, callbackstr, name, description, unit] = processAsynchronousInputs(...
                callback, name, description, unit);
            id = obj.Proxy.createObservableCounter(name, description, unit, callbackstr);
            ObservableCounterproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ObservableCounterProxy", "ID", id);
            obscounter = opentelemetry.metrics.ObservableCounter(ObservableCounterproxy, name, description, unit, callback);
        end

        function obsudcounter = createObservableUpDownCounter(obj, callback, name, description, unit)
            % CREATEOBSERVABLEUPDOWNCOUNTER Create an observable UpDownCounter
            %    C = CREATEOBSERVABLEUPDOWNCOUNTER(M, CALLBACK, NAME) 
            %    creates an observable UpDownCounter with the specified 
            %    callback function and name. The callback function, 
            %    specified as a function handle, must accept no input and 
            %    return one output of type opentelemetry.metrics.ObservableResult.
            %    The UpDownCounter's value can increase or decrease.
            %
            %    C = CREATEOBSERVABLEUPDOWNCOUNTER(M, CALLBACK, NAME, DESCRIPTION, UNIT) 
            %    also specifies a description and a unit.
            %     
            %    See also OPENTELEMETRY.METRICS.OBSERVABLERESULT, 
            %    CREATEOBSERVABLECOUNTER, CREATEOBSERVABLEGAUGE, CREATEUPDOWNCOUNTER
            arguments
                obj
                callback
                name
                description = ""
                unit = ""
            end

            [callback, callbackstr, name, description, unit] = processAsynchronousInputs(...
                callback, name, description, unit);
            id = obj.Proxy.createObservableUpDownCounter(name, description, unit, callbackstr);
            ObservableUpDownCounterproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ObservableUpDownCounterProxy", "ID", id);
            obsudcounter = opentelemetry.metrics.ObservableUpDownCounter(...
                ObservableUpDownCounterproxy, name, description, unit, callback);
        end

        function obsgauge = createObservableGauge(obj, callback, name, description, unit)
            % CREATEOBSERVABLEGAUGE Create an observable gauge
            %    C = CREATEOBSERVABLEGAUGE(M, CALLBACK, NAME) creates an 
            %    observable gauge with the specified callback function 
            %    and name. The callback function, specified as a 
            %    function handle, must accept no input and return one
            %    output of type opentelemetry.metrics.ObservableResult.
            %    A gauge's value can increase or decrease but it should 
            %    never be summed in aggregation.
            %
            %    C = CREATEOBSERVABLEGAUGE(M, CALLBACK NAME, DESCRIPTION, UNIT) 
            %    also specifies a description and a unit.
            %     
            %    See also OPENTELEMETRY.METRICS.OBSERVABLERESULT, 
            %    CREATEOBSERVABLECOUNTER, CREATEOBSERVABLEUPDOWNCOUNTER
            arguments
                obj
                callback
                name
                description = ""
                unit = ""
            end

            [callback, callbackstr, name, description, unit] = processAsynchronousInputs(...
                callback, name, description, unit);
            id = obj.Proxy.createObservableGauge(name, description, unit, callbackstr);
            ObservableGaugeproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ObservableGaugeProxy", "ID", id);
            obsgauge = opentelemetry.metrics.ObservableGauge(...
                ObservableGaugeproxy, name, description, unit, callback);
        end
    end    
end

function [name, description, unit] = processSynchronousInputs(name, ...
    description, unit)
import opentelemetry.common.mustBeScalarString
name = mustBeScalarString(name);
description = mustBeScalarString(description);
unit = mustBeScalarString(unit);
end

function [callback, callbackstr, name, description, unit] = processAsynchronousInputs(...
    callback, name, description, unit)
[name, description, unit] = processSynchronousInputs(name, description, unit);
if isa(callback, "function_handle")
    callbackstr = string(func2str(callback));
    if ~startsWith(callbackstr, '@')   % do not allow anonymous functions for now
        return
    end
end
% if we get here, callback is invalid
callback = [];
callbackstr = "";
end
