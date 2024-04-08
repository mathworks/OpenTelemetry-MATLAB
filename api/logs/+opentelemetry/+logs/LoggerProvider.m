classdef LoggerProvider < handle
    % A logger provider stores a set of configurations used in a log
    % system.

    % Copyright 2024 The MathWorks, Inc.

    properties (Access={?opentelemetry.sdk.logs.LoggerProvider, ...
            ?opentelemetry.sdk.common.Cleanup})
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.logs.Provider, ?opentelemetry.sdk.logs.LoggerProvider})
        function obj = LoggerProvider(skip)
            % constructor
            % "skip" input signals skipping construction
            if nargin < 1 || skip ~= "skip"
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.LoggerProviderProxy", ...
                    "ConstructorArguments", {});
            end
        end
    end

    methods
        function logger = getLogger(obj, lgname, lgversion, lgschema)
            % GETLOGGER Create a logger object used to generate logs.
            %    LG = GETLOGGER(LP, NAME) returns a logger with the name
            %    NAME that uses all the configurations specified in logger 
            %    provider LP.
            %
            %    LG = GETLOGGER(LP, NAME, VERSION, SCHEMA) also specifies
            %    the logger version and the URL that documents the schema
            %    of the generated logs.
            %
            %    See also OPENTELEMETRY.LOGS.LOGGER
            arguments
                obj
                lgname
                lgversion = ""
                lgschema = ""
            end
            % name, version, schema accepts any types that can convert to a
            % string
            import opentelemetry.common.mustBeScalarString
            lgname = mustBeScalarString(lgname);          
            lgversion = mustBeScalarString(lgversion);
            lgschema = mustBeScalarString(lgschema);
            id = obj.Proxy.getLogger(lgname, lgversion, lgschema);
            loggerproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.LoggerProxy", "ID", id);
            logger = opentelemetry.logs.Logger(loggerproxy, lgname, lgversion, lgschema);
        end
        
        function setLoggerProvider(obj)
            % SETLOGGERPROVIDER Set global instance of logger provider
            %    SETLOGGERPROVIDER(LP) sets the logger provider LP as
            %    the global instance.
            %
            %    See also OPENTELEMETRY.LOGS.PROVIDER.GETLOGGERPROVIDER
            obj.Proxy.setLoggerProvider();
        end
    end

    methods(Access=?opentelemetry.sdk.common.Cleanup)
        function postShutdown(obj)
            % POSTSHUTDOWN  Handle post-shutdown tasks
            obj.Proxy.postShutdown();
        end
    end
end
