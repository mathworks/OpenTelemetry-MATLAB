classdef TracerProvider
% An SDK implementation of tracer provider, which stores a set of configurations used 
% in a distributed tracing system.

% Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy
    end

    properties (SetAccess=private)
        SpanProcessor
        Sampler
    end

    methods
        function obj = TracerProvider(processor, optionnames, optionvalues)
    	    arguments
     	       processor {mustBeA(processor, ["opentelemetry.sdk.trace.SimpleSpanProcessor",...
    		       "opentelemetry.sdk.trace.BatchSpanProcessor"])} = ...
    		       opentelemetry.sdk.trace.SimpleSpanProcessor()
            end

            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = "Sampler";
            foundsampler = false;
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Sampler")
                    if ~(isa(valuei, "opentelemetry.sdk.trace.AlwaysOnSampler") || ...
                            isa(valuei, "opentelemetry.sdk.trace.AlwaysOffSampler") || ...
                            isa(valuei, "opentelemetry.sdk.trace.TraceIdRatioBasedSampler"))
                        error("Sampler must be an instance of one of the sampler classes");
                    end
                    sampler = valuei;
                    foundsampler = true;
                end
            end
            if ~foundsampler
                sampler = opentelemetry.sdk.trace.AlwaysOnSampler;
            end
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.TracerProviderProxy", ...
                "ConstructorArguments", {processor.Proxy.ID, sampler.Proxy.ID});
            obj.SpanProcessor = processor;
            obj.Sampler = sampler;
        end
        
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
