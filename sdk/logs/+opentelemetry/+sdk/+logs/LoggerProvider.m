classdef LoggerProvider < opentelemetry.logs.LoggerProvider & handle
    % An SDK implementation of logger provider, which stores a set of configurations used
    % in a logging system.

    % Copyright 2024 The MathWorks, Inc.

    properties(Access=private)
        isShutdown (1,1) logical = false
    end

    properties (SetAccess=private)
        LogRecordProcessor   % Whether logs should be sent immediately or batched
        Resource             % Attributes attached to all logs
    end

    methods
        function obj = LoggerProvider(processor, optionnames, optionvalues)
            % SDK implementation of logger provider
            %    LP = OPENTELEMETRY.SDK.LOGS.LOGGERPROVIDER creates a logger
            %    provider that uses a simple log record processor and default configurations.
            %
            %    LP = OPENTELEMETRY.SDK.LOGS.LOGGERPROVIDER(P) uses log record 
            %    processor P. P can be a simple or batched log record processor.
            %
            %    LP = OPENTELEMETRY.SDK.LOGS.LOGGERPROVIDER(R, PARAM1, VALUE1,
            %    PARAM2, VALUE2, ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Resource"    - Additional resource attributes.
            %                       Specified as a dictionary.
            %
            %    See also OPENTELEMETRY.SDK.LOGS.SIMPLELOGRECORDPROCESSOR, 
            %    OPENTELEMETRY.SDK.LOGS.BATCHLOGRECORDPROCESSOR

            arguments
     	        processor {mustBeA(processor, ["opentelemetry.sdk.logs.LogRecordProcessor", ...
                   "libmexclass.proxy.Proxy"])} = ...
    	    	            opentelemetry.sdk.logs.SimpleLogRecordProcessor()
            end           
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            % explicit call to superclass constructor to make it a no-op
            obj@opentelemetry.logs.LoggerProvider("skip");

            if isa(processor, "libmexclass.proxy.Proxy")
                % This code branch is used to support conversion from API
                % LoggerProvider to SDK equivalent, needed internally by
                % opentelemetry.sdk.logs.Cleanup
                lpproxy = processor;  % rename the variable
                assert(lpproxy.Name == "libmexclass.opentelemetry.LoggerProviderProxy");
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.sdk.LoggerProviderProxy", ...
                    "ConstructorArguments", {lpproxy.ID});
                % leave other properties unassigned, they won't be used
            else
                validnames = "Resource";
                resourcekeys = string.empty();
                resourcevalues = {};

                resource = dictionary(resourcekeys, resourcevalues);
                for i = 1:length(optionnames)
                    namei = validatestring(optionnames{i}, validnames);
                    valuei = optionvalues{i};
                    if strcmp(namei, "Resource")
                        if ~isa(valuei, "dictionary")
                            error("opentelemetry:sdk:logs:LoggerProvider:InvalidResourceType", ...
                                "Resource input must be a dictionary.");
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

                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.sdk.LoggerProviderProxy", ...
                    "ConstructorArguments", {processor.Proxy.ID, resourcekeys, ...
                    resourcevalues});
                obj.LogRecordProcessor = processor;
                obj.Resource = resource;
            end
        end

        function addLogRecordProcessor(obj, processor)
            % ADDLOGRECORDPROCESSOR Add an additional log record processor
            %    ADDLOGRECORDPROCESSOR(LP, P) adds an additional log record
            %    processor P to the list of log record processors used by 
            %    logger provider LP.
            %
            %    See also OPENTELEMETRY.SDK.LOGS.SIMPLELOGRECORDPROCESSOR, 
            %    OPENTELEMETRY.SDK.LOGS.BATCHLOGRECORDPROCESSOR
            arguments
         	    obj
                processor (1,1) {mustBeA(processor, "opentelemetry.sdk.logs.LogRecordProcessor")}
            end
            obj.Proxy.addProcessor(processor.Proxy.ID);
            obj.LogRecordProcessor = [obj.LogRecordProcessor processor];
        end

        function success = shutdown(obj)
            % SHUTDOWN  Shutdown 
            %    SUCCESS = SHUTDOWN(LP) shuts down all log record processors associated 
            %    with logger provider LP and return a logical that indicates 
            %    whether shutdown was successful.
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
            %    SUCCESS = FORCEFLUSH(LP) immediately exports all log
            %    records that have not yet been exported. Returns a logical 
            %    that indicates whether force flush was successful.
            %
            %    SUCCESS = FORCEFLUSH(LP, TIMEOUT) specifies a TIMEOUT
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
end
