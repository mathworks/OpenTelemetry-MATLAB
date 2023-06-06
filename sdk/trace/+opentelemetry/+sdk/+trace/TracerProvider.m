classdef TracerProvider < handle
% An SDK implementation of tracer provider, which stores a set of configurations used 
% in a distributed tracing system.

% Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=private)
        SpanProcessor   % Whether spans should be sent immediately or batched
        Sampler         % Sampling policy on generated spans
        Resource        % Attributes attached to all spans
    end

    methods
        function obj = TracerProvider(processor, optionnames, optionvalues)
            % SDK implementation of tracer provider
            %    TP = OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER creates a tracer 
            %    provider that uses a simple span processor and default configurations.
            %
            %    TP = OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER(P) uses span 
            %    processor P. P can be a simple or batched span processor.
            %
            %    TP = OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER(P, PARAM1, VALUE1, 
            %    PARAM2, VALUE2, ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Sampler"     - Sampling policy. Default is always on.
            %       "Resource"    - Additional resource attributes.
            %                       Specified as a dictionary.
            %
            %    See also OPENTELEMETRY.SDK.TRACE.SIMPLESPANPROCESSOR,
            %    OPENTELEMETRY.SDK.TRACE.BATCHSPANPROCESSOR,
            %    OPENTELEMETRY.SDK.TRACE.ALWAYSONSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.ALWAYSOFFSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.TRACEIDRATIOBASEDSAMPLER,
            %    OPENTELEMETRY.SDK.TRACE.PARENTBASEDSAMPLER

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
            % ADDSPANPROCESSOR Add an additional span processor to process the generated spans 
            %    ADDSPANPROCESSOR(TP, P) adds an additional span processor
            %    P to the list of span processors used by tracer provider
            %    TP.
            % 
            %    See also OPENTELEMETRY.SDK.TRACE.SIMPLESPANPROCESSOR,
            %    OPENTELEMETRY.SDK.TRACE.BATCHSPANPROCESSOR
            arguments
                obj
                processor (1,1) {mustBeA(processor, "opentelemetry.sdk.trace.SpanProcessor")}
            end
            obj.Proxy.addSpanProcessor(processor.Proxy.ID);
            obj.SpanProcessor(end+1) = processor;  % append
        end

        function tracer = getTracer(obj, trname, trversion, trschema)
            % GETTRACER Create a tracer object used to generate spans
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
            % SETTRACERPROVIDER Set global instance of tracer provider
            %    SETTRACERPROVIDER(TP) sets the SDK tracer provider TP as
            %    the global instance.
            %
            %    See also OPENTELEMETRY.TRACE.PROVIDER.GETTRACERPROVIDER
            obj.Proxy.setTracerProvider();
        end
    end
end
