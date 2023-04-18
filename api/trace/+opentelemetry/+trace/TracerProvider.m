classdef TracerProvider < handle
    % A tracer provider stores a set of configurations used in a distributed
    % tracing system.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy
    end

    methods (Access=?opentelemetry.trace.Provider)
        function obj = TracerProvider()
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TracerProviderProxy", ...
                "ConstructorArguments", {});
        end
    end

    methods
        function tracer = getTracer(obj, trname, trversion, trschema)
            arguments
                obj
                trname (1,:) {mustBeTextScalar}
                trversion (1,:) {mustBeTextScalar} = ""
                trschema (1,:) {mustBeTextScalar} = ""
            end
            trname = string(trname);
            trversion = string(trversion);
            trschema = string(trschema);
            id = obj.Proxy.getTracer(trname, trversion, trschema);
            tracerproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TracerProxy", "ID", id);
            tracer = opentelemetry.trace.Tracer(tracerproxy, trname, trversion, trschema);
        end
        
        function setTracerProvider(obj)
            obj.Proxy.setTracerProvider();
        end
    end
end
