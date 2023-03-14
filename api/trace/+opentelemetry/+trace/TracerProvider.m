classdef TracerProvider
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
            id = obj.Proxy.getTracer(string(trname), string(trversion), string(trschema));
            tracerproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TracerProxy", "ID", id);
            tracer = opentelemetry.trace.Tracer(tracerproxy);
        end
        
        function setTracerProvider(obj)
            obj.Proxy.setTracerProvider();
        end
    end
end
