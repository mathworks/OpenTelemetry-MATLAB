classdef Span < handle
% A span that represents a unit of work within a trace.  

% Copyright 2023-2024 The MathWorks, Inc.

    properties 
        Name  (1,1) string   % Name of span
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
        Ended  (1,1) logical = false
    end

    methods (Access={?opentelemetry.trace.Tracer, ?opentelemetry.trace.Context})
        function obj = Span(proxy, spname)
            if isa(proxy, "opentelemetry.context.Context")
                % called from opentelemetry.trace.Context.extractSpan
                context = proxy;
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.SpanProxy", ...
                    "ConstructorArguments", {context.Proxy.ID});
            else   % in is a proxy object
                obj.Proxy = proxy;
                obj.Name = spname;
            end
        end
    end

    methods
        function set.Name(obj, spname)
            isvalidname = isStringScalar(spname) || (ischar(spname) && isrow(spname));
            % ignore new name if invalid or span has already ended
            if isvalidname && ~obj.Ended %#ok<MCSUP>
                spname = string(spname);
                obj.Proxy.updateName(spname); %#ok<MCSUP>
                obj.Name = spname;
            end
        end

        function endSpan(obj, endtime)
            % ENDSPAN  End the span.
            %    ENDSPAN(SP) ends the span SP.
            %
            %    See also OPENTELEMETRY.TRACE.TRACER.STARTSPAN
            if nargin < 2
                obj.Proxy.endSpan();
            else
                if ~(isdatetime(endtime) && isscalar(endtime) && ~isnat(endtime))
                    % invalid end time, ignore
                    obj.Proxy.endSpan();
                else
                    obj.Proxy.endSpan(posixtime(endtime));
                end
            end
            obj.Ended = true;
        end

        function scope = makeCurrent(obj)
            % MAKECURRENT Make span the current span
            %    SCOPE = MAKECURRENT(SP) makes span SP the current span, by
            %    inserting it into the current context. Returns a scope
            %    object SCOPE that determines the duration when SP is current.
            %    When SCOPE is deleted, SP will no longer be current. 
            %
            %    See also OPENTELEMETRY.CONTEXT.CONTEXT,
            %    OPENTELEMETRY.GETCURRENTCONTEXT, OPENTELEMETRY.TRACE.SCOPE

            % return a warning if no output specified
            if nargout == 0
                warning("opentelemetry:trace:Span:makeCurrent:NoOutputSpecified", ...
                    "Calling makeCurrent without specifying an output has no effect.")
            end
            id = obj.Proxy.makeCurrent();
            scopeproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ScopeProxy", "ID", id);
    	    scope = opentelemetry.trace.Scope(scopeproxy);
        end

    	function setAttributes(obj, varargin)
            % SETATTRIBUTES Add attributes to span
            %    SETATTRIBUTES(SP, ATTRIBUTES) adds attributes to span SP,
            %    specified as a dictionary.
            %
            %    SETATTRIBUTES(SP, ATTRNAME1, ATTRVALUE1, ATTRNAME2,
            %    ATTRVALUE2, ...) specifies attributes as trailing
            %    name-value pairs.
            %
            %    See also ADDEVENT
            [attrnames, attrvalues] = opentelemetry.common.processAttributes(varargin);

            for i = 1:length(attrnames)
                obj.Proxy.setAttribute(attrnames(i), attrvalues{i});
            end
        end

        function addEvent(obj, eventname, varargin)
            % ADDEVENT  Record a event.
            %    ADDEVENT(SP, NAME) records a event with the specified name
            %    at the current time.
            %
            %    ADDEVENT(SP, NAME, TIME) also specifies a event time.
            %
            %    ADDEVENT(..., ATTRIBUTES) or ADDEVENT(..., ATTRNAME1,
            %    ATTRVALUE1, ATTRNAME2, ATTRVALUE2, ...) specifies
            %    attribute name/value pairs for the event, either as a
            %    dictionary or as trailing inputs.
            %
            %    See also SETATTRIBUTES

            % process event time input first
            if ~isempty(varargin) && isdatetime(varargin{1})
                eventtime = posixtime(varargin{1});
                varargin(1) = [];  % remove the time input from varargin
            else
                eventtime = posixtime(datetime("now"));
            end

            eventname = opentelemetry.common.mustBeScalarString(eventname);
            [attrnames, attrvalues] = opentelemetry.common.processAttributes(varargin);
            attrs = cell(2,length(attrnames));
            for i = 1:length(attrnames)
                attrs{1,i} = attrnames(i);
                attrs(2,i) = attrvalues(i);
            end
            obj.Proxy.addEvent(eventname, eventtime, attrs{:});        
        end

    	function setStatus(obj, status, description)
            % SETSTATUS  Set the span status.
            %    SETSTATUS(SP, STATUS) sets the span status as "Ok" or
            %    "Error".
            % 
            %    SETSTATUS(SP, STATUS, DESC) also specifies a description.
            %    Description is only recorded if status is "Error".
            try
                status = validatestring(status, ["Unset", "Ok", "Error"]);
            catch
                % new status is not valid, ignore
                return
            end
            if nargin < 3
                description = "";
            else
                description = opentelemetry.common.mustBeScalarString(description);
            end
    	    obj.Proxy.setStatus(status, description);
    	end

        function context = getSpanContext(obj)
            % GETSPANCONTEXT  Span context object associated with this span.
            %    SPCTXT = GETSPANCONTEXT(SP) returns the span context
            %    object that records information such as trace and span
            %    IDs.
            %
            %    See also OPENTELEMETRY.TRACE.SPANCONTEXT
            contextid = obj.Proxy.getSpanContext();
            contextproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.SpanContextProxy", "ID", contextid);
            context = opentelemetry.trace.SpanContext(contextproxy);
        end

    	function tf = isRecording(obj)
            % ISRECORDING whether the span is recording and sending telemetry data.
            %    TF = ISRECORDING(SP)  returns true or false which
            %    indicates whether the span is recording and sending
            %    telemetry data. A span is no longer recording if it has
            %    already ended, is excluded during sampling, or is created
            %    from a span context propagated externally.
            tf = obj.Proxy.isRecording();
        end

        function context = insertSpan(obj, context)
            % INSERTSPAN Insert span into a context and return a new context.
            %    NEWCTXT = INSERTSPAN(SP, CTXT) inserts span SP into
            %    context CTXT and returns a new context.
            %    
            %    NEWCTXT = INSERTSPAN(SP)  inserts into the current context.
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
