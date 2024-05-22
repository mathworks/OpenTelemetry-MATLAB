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
        function emitLogRecord(obj, severity, body, trailingnames, trailingvalues)
            % EMITLOGRECORD  Create and emit a log record
            %    EMITLOGRECORD(LG, SEVERITY, BODY) emits a log record
            %    with the specified severity and body. Severity can be one
    	    %    of "trace", "debug", "info", "warn", "error", and "fatal",
            %    or it can also be a scalar integer between 1 and 24. Body
            %    can be any string, numeric, or logical scalar or array.
            %
            %    EMITLOGRECORD(LG, SEVERITY, BODY, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
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
               body
            end
            arguments (Repeating)
                trailingnames
                trailingvalues
            end
            import opentelemetry.common.processAttributes
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
                severitylist = ["trace" "trace2" "trace3" "trace4" "debug" ...
                    "debug2" "debug3" "debug4" "info" "info2" "info3" "info4" ...
                    "warn" "warn2" "warn3" "warn4" "error" "error2" "error3" ...
                    "error4" "fatal" "fatal2" "fatal3" "fatal4"];
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

    	    % body
    	    body = convertCharsToStrings(body);  % force char rows into strings

            if nargin <= 3
                obj.Proxy.emitLogRecord(severity, body);
            else
                % validate the trailing names and values
                optionnames = ["Context", "Timestamp", "Attributes"];

                % define default values
                contextid = intmax("uint64");   % default value which means no context supplied
                timestamp = NaN;
                attributekeys = string.empty();
                attributevalues = {};

                % variables to keep track of which proxy function to call
                specifyoptions = false;
                specifyattributes = false;

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
                            specifyoptions = true;
                        end
                    elseif strcmp(namei, "Timestamp")
                        valuei = trailingvalues{i};
                        if isdatetime(valuei) && isscalar(valuei) && ~isnat(valuei)
                            timestamp = posixtime(valuei);
                            specifyoptions = true;
                        end
                    elseif strcmp(namei, "Attributes")
                        [attributekeys, attributevalues] = processAttributes(trailingvalues{i}, true);
                        specifyattributes = true;
                    end
                end

                if ~specifyoptions && ~specifyattributes
                    obj.Proxy.emitLogRecord(severity, body);
                elseif specifyoptions && ~specifyattributes
                    obj.Proxy.emitLogRecord(severity, body, contextid, timestamp);
                elseif ~specifyoptions && specifyattributes
                    obj.Proxy.emitLogRecord(severity, body, attributekeys, attributevalues);
                else  % specifyoptions && specifyattributes
                    obj.Proxy.emitLogRecord(severity, body, contextid, timestamp, ...
                        attributekeys, attributevalues);
                end
            end
        end

        function trace(obj, body, varargin)
            % TRACE  Create and emit a log record with "trace" severity
            %    TRACE(LG, BODY) emits a log record with "trace" severity. 
            %    Body can be any string, numeric, or logical scalar or array.
            %
            %    TRACE(LG, BODY, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
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
            emitLogRecord(obj, 1, body, varargin{:});
        end

        function debug(obj, body, varargin)
            % DEBUG  Create and emit a log record with "debug" severity
            %    DEBUG(LG, BODY) emits a log record with "debug" severity. 
            %    Body can be any string, numeric, or logical scalar or array.
            %
            %    DEBUG(LG, BODY, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
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
            emitLogRecord(obj, 5, body, varargin{:});
        end

        function info(obj, body, varargin)
            % INFO  Create and emit a log record with "info" severity
            %    INFO(LG, BODY) emits a log record with "info" severity. 
            %    Body can be any string, numeric, or logical scalar or array.
            %
            %    INFO(LG, BODY, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
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
            emitLogRecord(obj, 9, body, varargin{:});
        end

        function warn(obj, body, varargin)
            % WARN  Create and emit a log record with "warn" severity
            %    WARN(LG, BODY) emits a log record with "warn" severity. 
            %    Body can be any string, numeric, or logical scalar or array.
            %
            %    WARN(LG, BODY, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
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
            emitLogRecord(obj, 13, body, varargin{:});
        end

        function error(obj, body, varargin)
            % ERROR  Create and emit a log record with "error" severity
            %    ERROR(LG, BODY) emits a log record with "error" severity. 
            %    Body can be any string, numeric, or logical scalar or array.
            %
            %    ERROR(LG, BODY, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
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
            emitLogRecord(obj, 17, body, varargin{:});
        end

        function fatal(obj, body, varargin)
            % FATAL  Create and emit a log record with "fatal" severity
            %    FATAL(LG, BODY) emits a log record with "fatal" severity. 
            %    Body can be any string, numeric, or logical scalar or array.
            %
            %    FATAL(LG, BODY, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
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
            emitLogRecord(obj, 21, body, varargin{:});
        end
    end

end
