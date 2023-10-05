classdef Meter < handle
    % A Meter creates metric instruments, capturing measurements about a service at runtime. 
    % Meters are created from Meter Providers.

    % Copyright 2023 The MathWorks, Inc.

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
    
        function counter = createCounter(obj, ctname, ctdescription, ctunit)
            arguments
                obj
                ctname
                ctdescription = ""
                ctunit = ""
            end
            import opentelemetry.common.mustBeScalarString
            ctname = mustBeScalarString(ctname);          
            ctdescription = mustBeScalarString(ctdescription);
            ctunit = mustBeScalarString(ctunit);
            id = obj.Proxy.createCounter(ctname, ctdescription, ctunit);
            CounterProxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.CounterProxy", "ID", id);
            counter = opentelemetry.metrics.Counter(CounterProxy, ctname, ctdescription, ctunit);
        end


        function updowncounter = createUpDownCounter(obj, ctname, ctdescription, ctunit)
            arguments
                obj
                ctname
                ctdescription = ""
                ctunit = ""
            end

            import opentelemetry.common.mustBeScalarString
            ctname = mustBeScalarString(ctname);          
            ctdescription = mustBeScalarString(ctdescription);
            ctunit = mustBeScalarString(ctunit);
            id = obj.Proxy.createUpDownCounter(ctname, ctdescription, ctunit);
            UpDownCounterProxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.UpDownCounterProxy", "ID", id);
            updowncounter = opentelemetry.metrics.UpDownCounter(UpDownCounterProxy, ctname, ctdescription, ctunit);
        end


        function histogram = createHistogram(obj, hiname, hidescription, hiunit)
            arguments
                obj
                hiname
                hidescription = ""
                hiunit = ""
            end

            import opentelemetry.common.mustBeScalarString
            hiname = mustBeScalarString(hiname);          
            hidescription = mustBeScalarString(hidescription);
            hiunit = mustBeScalarString(hiunit);
            id = obj.Proxy.createHistogram(hiname, hidescription, hiunit);
            HistogramProxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.HistogramProxy", "ID", id);
            histogram = opentelemetry.metrics.Histogram(HistogramProxy, hiname, hidescription, hiunit);
        end

    end
        
end
