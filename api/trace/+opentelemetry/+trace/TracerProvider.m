classdef TracerProvider < handle
    % A tracer provider stores a set of configurations used in a distributed
    % tracing system.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access={?opentelemetry.sdk.trace.TracerProvider, ...
            ?opentelemetry.sdk.common.Cleanup})
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.trace.Provider, ?opentelemetry.sdk.trace.TracerProvider})
        function obj = TracerProvider(skip)
            % constructor
            % "skip" input signals skipping construction
            if nargin < 1 || skip ~= "skip"
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.TracerProviderProxy", ...
                    "ConstructorArguments", {});
            end
        end
    end

    methods
        function tracer = getTracer(obj, trname, trversion, trschema)
            % GETTRACER Create a tracer object used to generate spans.
            %    TR = GETTRACER(TP, NAME) returns a tracer with the name
            %    NAME that uses all the configurations specified in tracer
            %    provider TP.
            %
            %    TR = GETTRACER(TP, NAME, VERSION, SCHEMA) also specifies
            %    the tracer version and the URL that documents the schema
            %    of the generated spans.
            %
            %    See also OPENTELEMETRY.TRACE.TRACER
            arguments
                obj
                trname
                trversion = ""
                trschema = ""
            end
            % name, version, schema accepts any types that can convert to a
            % string
            import opentelemetry.common.mustBeScalarString
            trname = mustBeScalarString(trname);          
            trversion = mustBeScalarString(trversion);
            trschema = mustBeScalarString(trschema);
            id = obj.Proxy.getTracer(trname, trversion, trschema);
            tracerproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.TracerProxy", "ID", id);
            tracer = opentelemetry.trace.Tracer(tracerproxy, trname, trversion, trschema);
        end
        
        function setTracerProvider(obj)
            % SETTRACERPROVIDER Set global instance of tracer provider
            %    SETTRACERPROVIDER(TP) sets the tracer provider TP as
            %    the global instance.
            %
            %    See also OPENTELEMETRY.TRACE.PROVIDER.GETTRACERPROVIDER
            obj.Proxy.setTracerProvider();
        end
    end

    methods(Access=?opentelemetry.sdk.common.Cleanup)
        function postShutdown(obj)
            % POSTSHUTDOWN  Handle post-shutdown tasks
            obj.Proxy.postShutdown();
        end
    end
end
