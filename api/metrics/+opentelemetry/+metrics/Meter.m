classdef Meter < handle
    % A Meter that is used to create spans.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name    (1,1) string   % Meter name
        Version (1,1) string   % Meter version
        Schema  (1,1) string   % URL that documents the schema of the generated spans
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.sdk.metrics.MeterProvider})

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
            import opentelemetry.utils.mustBeScalarString
            ctname = mustBeScalarString(ctname);          
            ctdescription = mustBeScalarString(ctdescription);
            ctunit = mustBeScalarString(ctunit);
            id = obj.Proxy.createCounter(ctname, ctdescription, ctunit);
            Counterproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.CounterProxy", "ID", id);
            counter = opentelemetry.metrics.Counter(Counterproxy, ctname, ctdescription, ctunit);
        end

    end
        
end
