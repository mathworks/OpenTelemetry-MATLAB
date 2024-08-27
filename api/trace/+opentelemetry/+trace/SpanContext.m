classdef SpanContext < handle
% The part of a span that is propagated.

% Copyright 2023-2024 The MathWorks, Inc.

    properties (Dependent, SetAccess=private)
        TraceId (1,1) string     % Trace identifier represented as a string of 32 hexadecimal digits
        SpanId (1,1)  string     % Span identifier represented as a string of 16 hexadecimal digits
        TraceState (1,1) string  % Vendor-specific trace identification data, specified as comma-separated name-value pairs
        TraceFlags (1,1) string  % Details about the trace, such as a flag that represents whether the span is sampled
    end

    properties (Access=?opentelemetry.trace.Tracer)
        Proxy   % Proxy object to interface C++ code
    end   

    methods
        function obj = SpanContext(traceid, spanid, varargin)
            % Span context
            %    SC = OPENTELEMETRY.TRACE.SPANCONTEXT(TRACEID, SPANID)
            %    creates a span context with the specified trace and span
            %    IDs. Trace and span IDs must be strings or char vectors 
            %    containing a hexadecimal number. Trace IDs must be 32 
            %    hexadecimal digits long and span IDs must be 16 
            %    hexadecimal digits long. Valid IDs must be non-zero.
            %
            %    SC = OPENTELEMETRY.TRACE.SPANCONTEXT(TRACEID, SPANID, 
            %    PARAM1, VALUE1, PARAM2, VALUE2, ...) specifies optional
            %    parameter name/value pairs. Parameters are:
            %       "IsSampled"     - Whether span is sampled. Default is
            %                         true.
            %       "IsRemote"      - Whether span is created in a remote
            %                         process. Default is true.

            if nargin == 1 && isa(traceid, "libmexclass.proxy.Proxy")
                % internal calls to constructor with a proxy
                obj.Proxy = traceid;  
            else
                narginchk(2, inf);
                traceid_len = 32;
                spanid_len = 16;
                if ~((isstring(traceid) || (ischar(traceid) && isrow(traceid))) && ...
                        strlength(traceid) == traceid_len && all(isstrprop(traceid, "xdigit")))
                    traceid = repmat('0', 1, traceid_len);  % replace any illegal values with an all-zeros invalid ID
                end
                if ~((isstring(spanid) || (ischar(spanid) && isrow(spanid))) && ...
                        strlength(spanid) == spanid_len && all(isstrprop(spanid, "xdigit")))
                    spanid = repmat('0', 1, spanid_len);  % replace any illegal values with an all-zeros invalid ID
                end
                % convert IDs from string to uint8 array
                traceid = uint8(hex2dec(reshape(char(traceid), 2, traceid_len/2).'));
                spanid = uint8(hex2dec(reshape(char(spanid), 2, spanid_len/2).'));

                % default option values
                issampled = true;
                isremote = true;
                includets = false;   % whether TraceState is specified
                if nargin > 2
                    optionnames = ["IsSampled", "IsRemote", "TraceState"];
                    for i = 1:2:length(varargin)
                        try 
                            namei = validatestring(varargin{i}, optionnames);
                        catch
                            % invalid option, ignore
                            continue
                        end
                        valuei = varargin{i+1};
                        if strcmp(namei, "IsSampled")
                            if (isnumeric(valuei) || islogical(valuei)) && isscalar(valuei)
                                issampled = logical(valuei);
                            end
                        elseif strcmp(namei, "IsRemote")
                            if (isnumeric(valuei) || islogical(valuei)) && isscalar(valuei)
                                isremote = logical(valuei);
                            end
                        else  % strcmp(namei, "TraceState")
                            if isa(valuei, "dictionary")
                                try
                                    tskeysi = string(keys(valuei));
                                    tsvaluesi = string(values(valuei));
                                catch
                                    % invalid TraceState, ignore
                                    continue
                                end
                                tskeys = tskeysi;
                                tsvalues = tsvaluesi;
                                includets = true;
                            end
                        end
                    end
                end

                if includets
                    obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                        "libmexclass.opentelemetry.SpanContextProxy", ...
                        "ConstructorArguments", {traceid, spanid, issampled, ...
                        isremote, tskeys, tsvalues});
                else
                    obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                        "libmexclass.opentelemetry.SpanContextProxy", ...
                        "ConstructorArguments", {traceid, spanid, issampled, isremote});
                end
            end
        end
    end

    methods
        function traceid = get.TraceId(obj)
            traceid = obj.Proxy.getTraceId();
        end

        function spanid = get.SpanId(obj)
            spanid = obj.Proxy.getSpanId();
        end

        function tracestate = get.TraceState(obj)
            [keys, values] = obj.Proxy.getTraceState();
            tracestate = dictionary(keys, values);
        end

        function traceflags = get.TraceFlags(obj)
            traceflags = obj.Proxy.getTraceFlags();
        end

        function tf = isSampled(obj)
            % ISSAMPLED  Whether span is sampled.
            %    TF = ISSAMPLED(SPCTXT)  returns true or false to indicate
            %    whether span is sampled.
            %
            %    See also ISVALID, ISREMOTE
            tf = obj.Proxy.isSampled();
        end

        function tf = isValid(obj)
            % ISVALID  Whether span is valid.
            %    TF = ISVALID(SPCTXT) returns true or false to indicate
            %    whether span has valid and non-zero trace and span IDs.
            %
            %    See also ISSAMPLED, ISREMOTE
            tf = obj.Proxy.isValid();
        end

        function tf = isRemote(obj)
            % ISREMOTE  Whether span context is propagated from a remote parent.
            %    TF = ISREMOTE(SPCTXT) returns true or false to indicate
            %    whether span context is propagated from a remote parent.
            %
            %    See also OPENTELEMETRY.CONTEXT.PROPAGATION.EXTRACTCONTEXT,
            %    ISSAMPLED, ISVALID
            tf = obj.Proxy.isRemote();
        end

        function scope = makeCurrent(obj)
            % MAKECURRENT Make span the current span
            %    SCOPE = MAKECURRENT(SPCTXT) makes the span represented by
            %    span context SPCTXT as the current span, by
            %    inserting it into the current context. Returns a scope
            %    object SCOPE that determines the duration when span is current.
            %    When SCOPE is deleted, span will no longer be current. 
            %
            %    See also OPENTELEMETRY.CONTEXT.CONTEXT,
            %    OPENTELEMETRY.GETCURRENTCONTEXT, OPENTELEMETRY.TRACE.SCOPE

            % return a warning if no output specified
            if nargout == 0
                warning("opentelemetry:trace:SpanContext:makeCurrent:NoOutputSpecified", ...
                    "Calling makeCurrent without specifying an output has no effect.")
            end
            id = obj.Proxy.makeCurrent();
            scopeproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ScopeProxy", "ID", id);
    	    scope = opentelemetry.trace.Scope(scopeproxy);
        end

        function context = insertSpan(obj, context)
            % INSERTSPAN Insert span into a context and return a new context.
            %    NEWCTXT = INSERTSPAN(SPCTXT, CTXT) inserts the span 
            %    represented by span context SPCTXT into context CTXT and 
            %    returns a new context.
            %    
            %    NEWCTXT = INSERTSPAN(SPCTXT)  inserts into the current context.
            %
            %    See also OPENTELEMETRY.TRACE.CONTEXT.EXTRACTSPAN
            if nargin < 2
                context = opentelemetry.context.getCurrentContext();
            end
            contextid = obj.Proxy.insertSpan(context.Proxy.ID);
            contextproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ContextProxy", "ID", contextid);
            context = opentelemetry.context.Context(contextproxy);
        end
    end

end
