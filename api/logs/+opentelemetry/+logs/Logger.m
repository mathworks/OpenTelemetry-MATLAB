classdef Logger < handle
    % A logger that is used to emit log records

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name    (1,1) string   % Logger name
        Version (1,1) string   % Logger version
        Schema  (1,1) string   % URL that documents the schema of the generated log records
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.logs.LoggerProvider, ?opentelemetry.sdk.logs.LoggerProvider})
        function obj = Logger(proxy, lgname, lgversion, lgschema)
            % Private constructor. Use getLogger method of LoggerProvider
            % to create loggers.
            obj.Proxy = proxy;
            obj.Name = lgname;
            obj.Version = lgversion;
            obj.Schema = lgschema;
        end
    end

    methods
        function emitLogRecord(obj, severity, content, trailingnames, trailingvalues)
            % EMITLOGRECORD  Create and emit a log record
            %    EMITLOGRECORD(LG, SEVERITY, CONTENT) emits a log record
            %    with the specified severity and content. Severity is one
    	    %    of "trace", "debug", "info", "warn", "error", and "fatal". It
    	    %    can also be a scalar integer between 1 and 24. Content can be an
    	    %    array of type double, int32, uint32, int64, logical, or string.
            %
            %    EMITLOGRECORD(LG, SEVERITY, CONTENT, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Span contained in a context object.
            %       "Timestamp" - Timestamp of the log record specified as a
            %                     datetime. Default is the current time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %
            %    See also OPENTELEMETRY.LOGS.TRACE, OPENTELEMETRY.LOGS.DEBUG,
            %    OPENTELEMETRY.LOGS.INFO, OPENTELEMETRY.LOGS.WARN,
            %    OPENTELEMETRY.LOGS.ERROR, OPENTELEMETRY.LOGS.FATAL
            arguments
     	       obj
    	       severity
               content
            end
            arguments (Repeating)
                trailingnames
                trailingvalues
            end
            if isnumeric(severity) && isscalar(severity)
                % severity number
                if severity < 1 || severity > 24 || round(severity) ~= severity
                    severity = 0;   % invalid
                end
            elseif (isstring(severity) && isscalar(severity)) || ...
                    (ischar(severity) && isrow(severity)) 
                % severity text
                % Support 24 valid severity levels: trace, trace2, trace3,
                % trace4, debug, debug2, debug3, ...
                severitylist = ["trace", "debug", "info", "warn", "error", "fatal"];
                severitylist = reshape(severitylist + [""; "2"; "3"; "4"], 1, []);
                d = dictionary(severitylist, 1:length(severitylist));
                try
                    severity = d(lower(severity));
                catch
                    severity = 0;  % invalid
                end
            else
                % invalid severity
                severity = 0;
            end

    	    % content
    	    content = convertCharsToStrings(content);  % force char rows into strings

            % validate the trailing names and values
            optionnames = ["Context", "Timestamp", "Attributes"];
            
            % define default values
            contextid = intmax("uint64");   % default value which means no context supplied
            timestamp = NaN;
            attributekeys = string.empty();
            attributevalues = {};

            % Loop through Name-Value pairs
            for i = 1:length(trailingnames)
                try
                    namei = validatestring(trailingnames{i}, optionnames);
                catch
                    % invalid option, ignore
                    continue
                end
                if strcmp(namei, "Context")                    
                    context = trailingvalues{i};
                    if isa(context, "opentelemetry.context.Context")
                        contextid = context.Proxy.ID;
                    end
                elseif strcmp(namei, "Timestamp")
                    valuei = trailingvalues{i};
                    if isdatetime(valuei) && isscalar(valuei) && ~isnat(valuei)
                        timestamp = posixtime(valuei);
                    end
                elseif strcmp(namei, "Attributes")
                    valuei = trailingvalues{i};
                    if isa(valuei, "dictionary")
                        attributekeys = keys(valuei);
                        attributevalues = values(valuei,"cell");
                        % collapse one level of cells, as this may be due to
                        % a behavior of dictionary.values
                        if all(cellfun(@iscell, attributevalues))
                            attributevalues = [attributevalues{:}];
                        end
                    end
                end
            end
            obj.Proxy.emitLogRecord(severity, content, contextid, timestamp, ...
                attributekeys, attributevalues);
        end

        function trace(obj, content, varargin)
            % TRACE  Create and emit a log record with "trace" severity
            %    TRACE(LG, CONTENT) emits a log record with "trace" severity. 
            %    Content can be an array of type double, int32, uint32, 
            %    int64, logical, or string.
            %
            %    TRACE(LG, CONTENT, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Span contained in a context object.
            %       "Timestamp" - Timestamp of the log record specified as a
            %                     datetime. Default is the current time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %
            %    See also OPENTELEMETRY.LOGS.DEBUG,
            %    OPENTELEMETRY.LOGS.INFO, OPENTELEMETRY.LOGS.WARN,
            %    OPENTELEMETRY.LOGS.ERROR, OPENTELEMETRY.LOGS.FATAL,
            %    OPENTELEMETRY.LOGS.EMITLOGRECORD
            emitLogRecord(obj, "trace", content, varargin{:});
        end

        function debug(obj, content, varargin)
            % DEBUG  Create and emit a log record with "debug" severity
            %    DEBUG(LG, CONTENT) emits a log record with "debug" severity. 
            %    Content can be an array of type double, int32, uint32, 
            %    int64, logical, or string.
            %
            %    DEBUG(LG, CONTENT, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Span contained in a context object.
            %       "Timestamp" - Timestamp of the log record specified as a
            %                     datetime. Default is the current time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %
            %    See also OPENTELEMETRY.LOGS.TRACE,
            %    OPENTELEMETRY.LOGS.INFO, OPENTELEMETRY.LOGS.WARN,
            %    OPENTELEMETRY.LOGS.ERROR, OPENTELEMETRY.LOGS.FATAL,
            %    OPENTELEMETRY.LOGS.EMITLOGRECORD
            emitLogRecord(obj, "debug", content, varargin{:});
        end

        function info(obj, content, varargin)
            % INFO  Create and emit a log record with "info" severity
            %    INFO(LG, CONTENT) emits a log record with "info" severity. 
            %    Content can be an array of type double, int32, uint32, 
            %    int64, logical, or string.
            %
            %    INFO(LG, CONTENT, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Span contained in a context object.
            %       "Timestamp" - Timestamp of the log record specified as a
            %                     datetime. Default is the current time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %
            %    See also OPENTELEMETRY.LOGS.TRACE,
            %    OPENTELEMETRY.LOGS.DEBUG, OPENTELEMETRY.LOGS.WARN,
            %    OPENTELEMETRY.LOGS.ERROR, OPENTELEMETRY.LOGS.FATAL,
            %    OPENTELEMETRY.LOGS.EMITLOGRECORD
            emitLogRecord(obj, "info", content, varargin{:});
        end

        function warn(obj, content, varargin)
            % WARN  Create and emit a log record with "warn" severity
            %    WARN(LG, CONTENT) emits a log record with "warn" severity. 
            %    Content can be an array of type double, int32, uint32, 
            %    int64, logical, or string.
            %
            %    WARN(LG, CONTENT, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Span contained in a context object.
            %       "Timestamp" - Timestamp of the log record specified as a
            %                     datetime. Default is the current time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %
            %    See also OPENTELEMETRY.LOGS.TRACE,
            %    OPENTELEMETRY.LOGS.DEBUG, OPENTELEMETRY.LOGS.INFO,
            %    OPENTELEMETRY.LOGS.ERROR, OPENTELEMETRY.LOGS.FATAL,
            %    OPENTELEMETRY.LOGS.EMITLOGRECORD
            emitLogRecord(obj, "warn", content, varargin{:});
        end

        function error(obj, content, varargin)
            % ERROR  Create and emit a log record with "error" severity
            %    ERROR(LG, CONTENT) emits a log record with "error" severity. 
            %    Content can be an array of type double, int32, uint32, 
            %    int64, logical, or string.
            %
            %    ERROR(LG, CONTENT, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Span contained in a context object.
            %       "Timestamp" - Timestamp of the log record specified as a
            %                     datetime. Default is the current time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %
            %    See also OPENTELEMETRY.LOGS.TRACE,
            %    OPENTELEMETRY.LOGS.DEBUG, OPENTELEMETRY.LOGS.INFO,
            %    OPENTELEMETRY.LOGS.WARN, OPENTELEMETRY.LOGS.FATAL,
            %    OPENTELEMETRY.LOGS.EMITLOGRECORD
            emitLogRecord(obj, "error", content, varargin{:});
        end

        function fatal(obj, content, varargin)
            % FATAL  Create and emit a log record with "fatal" severity
            %    FATAL(LG, CONTENT) emits a log record with "fatal" severity. 
            %    Content can be an array of type double, int32, uint32, 
            %    int64, logical, or string.
            %
            %    FATAL(LG, CONTENT, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Span contained in a context object.
            %       "Timestamp" - Timestamp of the log record specified as a
            %                     datetime. Default is the current time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %
            %    See also OPENTELEMETRY.LOGS.TRACE,
            %    OPENTELEMETRY.LOGS.DEBUG, OPENTELEMETRY.LOGS.INFO,
            %    OPENTELEMETRY.LOGS.WARN, OPENTELEMETRY.LOGS.ERROR,
            %    OPENTELEMETRY.LOGS.EMITLOGRECORD
            emitLogRecord(obj, "fatal", content, varargin{:});
        end
    end

end
