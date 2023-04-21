classdef TracerProvider < handle
% An SDK implementation of tracer provider, which stores a set of configurations used 
% in a distributed tracing system.

% Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy
    end

    properties (SetAccess=private)
        SpanProcessor
        Sampler
        Resource
    end

    methods
        function obj = TracerProvider(processor, optionnames, optionvalues)
    	    arguments
     	       processor {mustBeA(processor, "opentelemetry.sdk.trace.SpanProcessor")} = ...
    		       opentelemetry.sdk.trace.SimpleSpanProcessor()
            end

            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["Sampler", "Resource"];
            foundsampler = false;
            resourcekeys = string.empty();
            resourcevalues = {};
            resource = dictionary(resourcekeys, resourcevalues);
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Sampler")
                    if ~isa(valuei, "opentelemetry.sdk.trace.Sampler")
                        error("Sampler must be an instance of one of the sampler classes");
                    end
                    sampler = valuei;
                    foundsampler = true;
                else  % "Resource"
                    if ~isa(valuei, "dictionary")
                        error("Attibutes input must be a dictionary.");
                    end
                    resource = valuei;
                    resourcekeys = keys(valuei);
                    resourcevalues = values(valuei,"cell");
                    % collapse one level of cells, as this may be due to
                    % a behavior of dictionary.values
                    if all(cellfun(@iscell, resourcevalues))
                        resourcevalues = [resourcevalues{:}];
                    end
                end
            end
            if ~foundsampler
                sampler = opentelemetry.sdk.trace.AlwaysOnSampler;
            end
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.TracerProviderProxy", ...
                "ConstructorArguments", {processor.Proxy.ID, sampler.Proxy.ID, ...
                resourcekeys, resourcevalues});
            obj.SpanProcessor = processor;
            obj.Sampler = sampler;
            obj.Resource = resource;
        end
        
        function addSpanProcessor(obj, processor)
            arguments
                obj
                processor (1,1) {mustBeA(processor, "opentelemetry.sdk.trace.SpanProcessor")}
            end
            obj.Proxy.addSpanProcessor(processor.Proxy.ID);
            obj.SpanProcessor(end+1) = processor;  % append
        end

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
