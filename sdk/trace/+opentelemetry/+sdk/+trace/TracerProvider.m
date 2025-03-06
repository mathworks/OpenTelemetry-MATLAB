classdef TracerProvider < opentelemetry.trace.TracerProvider & handle
    % An SDK implementation of tracer provider, which stores a set of configurations used
    % in a distributed tracing system.

    % Copyright 2023-2025 The MathWorks, Inc.

    properties(Access=private)
        isShutdown (1,1) logical = false
    end

    properties (SetAccess=private)
        SpanProcessor   % Whether spans should be sent immediately or batched
        Sampler         % Sampling policy on generated spans
        Resource        % Attributes attached to all spans
    end

    methods
        function obj = TracerProvider(varargin)
            % SDK implementation of tracer provider
            %    TP = OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER creates a tracer 
            %    provider that uses a simple span processor and default configurations.
            %
            %    TP = OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER(P) uses span 
            %    processor P. P can be a simple or batched span processor.
            %
            %    TP = OPENTELEMETRY.SDK.TRACE.TRACERPROVIDER(..., PARAM1, VALUE1, 
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

            % explicit call to superclass constructor to make it a no-op
            obj@opentelemetry.trace.TracerProvider("skip");

            if nargin == 1 && isa(varargin{1}, "libmexclass.proxy.Proxy")
                % This code branch is used to support conversion from API
                % TracerProvider to SDK equivalent, needed internally by
                % opentelemetry.sdk.trace.Cleanup
                tpproxy = varargin{1};
                assert(tpproxy.Name == "libmexclass.opentelemetry.TracerProviderProxy");
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.sdk.TracerProviderProxy", ...
                    "ConstructorArguments", {tpproxy.ID});
                % leave other properties unassigned, they won't be used
            else
                % Code branch for construction from inputs
                if nargin == 0 || ~isa(varargin{1}, "opentelemetry.sdk.trace.SpanProcessor")
                    processor = opentelemetry.sdk.trace.SimpleSpanProcessor();  % default span processor
                else
                    processor = varargin{1};
                    varargin(1) = [];
                end
                obj.processOptions(processor, varargin{:});
            end           
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
            if ~obj.isShutdown
                obj.Proxy.addSpanProcessor(processor.Proxy.ID);
                obj.SpanProcessor(end+1) = processor;  % append
            end
        end

        function success = shutdown(obj)
            % SHUTDOWN  Shutdown 
            %    SUCCESS = SHUTDOWN(TP) shuts down all span processors associated with tracer provider TP
    	    %    and return a logical that indicates whether shutdown was successful.
            %
            %    See also FORCEFLUSH
            if ~obj.isShutdown
                success = obj.Proxy.shutdown();
                obj.isShutdown = success;
            else
                success = true;
            end
        end

        function success = forceFlush(obj, timeout)
            % FORCEFLUSH Force flush
            %    SUCCESS = FORCEFLUSH(TP) immediately exports all spans
            %    that have not yet been exported. Returns a logical that
            %    indicates whether force flush was successful.
            %
            %    SUCCESS = FORCEFLUSH(TP, TIMEOUT) specifies a TIMEOUT
            %    duration. Force flush must be completed within this time,
            %    or else it will fail.
            %
            %    See also SHUTDOWN
            if obj.isShutdown
                success = false;
            elseif nargin < 2 || ~isa(timeout, "duration")  % ignore timeout if not a duration
                success = obj.Proxy.forceFlush();
            else
                success = obj.Proxy.forceFlush(milliseconds(timeout)*1000); % convert to microseconds
            end
        end
    end

    methods(Access=private)
        function processOptions(obj, processor, optionnames, optionvalues)
            arguments
       	       obj
               processor
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
                        error("opentelemetry:sdk:trace:TracerProvider:InvalidSamplerType", ...
                            "Sampler must be an instance of one of the sampler classes");
                    end
                    sampler = valuei;
                    foundsampler = true;
                else  % "Resource"
                    if ~isa(valuei, "dictionary")
                        error("opentelemetry:sdk:trace:TracerProvider:InvalidResourceType", ...
                            "Attibutes input must be a dictionary.");
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
            [resourcekeys, resourcevalues] = opentelemetry.sdk.common.addDefaultResource(...
                resourcekeys, resourcevalues);
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
    end
end
