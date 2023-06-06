classdef Span < handle
% A span that represents a unit of work within a trace.  

% Copyright 2023 The MathWorks, Inc.

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
                obj.Name = "";   % unknown name when span is extracted from context, leave blank
            else   % in is a proxy object
                obj.Proxy = proxy;
                obj.Name = spname;
            end
        end
    end

    methods
        function set.Name(obj, spname)
            arguments
     	       obj
    	       spname (1,:) {mustBeTextScalar}
            end
            % ignore new name if span has already ended
            if ~obj.Ended %#ok<MCSUP>
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
                endposixtime = NaN;
            else
                if ~(isdatetime(endtime) && isscalar(endtime) && ~isnat(endtime))
                    error("End time must be a scalar datetime that is not NaT.");
                end
                endposixtime = posixtime(endtime);
            end
            obj.Proxy.endSpan(endposixtime);
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
            nin = length(varargin);
    	    if nin == 1 && isa(varargin{1}, "dictionary")
                % dictionary case
     	       attrtbl = entries(varargin{1});
               nattr = height(attrtbl);
    	       if ~iscell(attrtbl.(2))   % force attribute values to be cell array
                   attrtbl.(2) = mat2cell(attrtbl.(2),ones(1, nattr));
    	       end
               for i = 1:nattr
                   attrname = attrtbl{i,1};
      	          attrvalue = attrtbl{i,2}{1};
                  [~, attrvalue] = obj.processAttribute(attrname, attrvalue);
    	          attrtbl{i,2}{1} = attrvalue;
               end
    	       for i = 1:nattr
                   obj.Proxy.setAttribute(string(attrtbl{i,1}), attrtbl{i,2}{1});
    	       end
    	    else
                % NV pairs
                if rem(nin,2) ~= 0
                    error("Incorrect number of input arguments.");
                end
    	       for i = 1:2:nin
                   attrname = varargin{i};
    	          attrvalue = varargin{i+1};
                  [~, attrvalue] = obj.processAttribute(attrname, attrvalue);
    	          varargin{i+1} = attrvalue;
    	       end
    	       for i = 1:2:nin
                   obj.Proxy.setAttribute(string(varargin{i}), varargin{i+1});
    	       end
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
            arguments
        	       obj
                   eventname (1,:) {mustBeTextScalar}
            end
            arguments (Repeating)
                varargin
            end

            % process event time input first
            if ~isempty(varargin) && isdatetime(varargin{1})
                eventtime = posixtime(varargin{1});
                varargin(1) = [];  % remove the time input from varargin
            else
                eventtime = posixtime(datetime("now"));
            end

            % TODO: Implement some sort of code sharing with setAttributes
            nin = length(varargin);
            if nin == 1 && isa(varargin{1}, "dictionary")
                % dictionary case
       	       attrtbl = entries(varargin{1});
               nattr = height(attrtbl);
               if ~iscell(attrtbl.(2))   % force attribute values to be cell array
                   attrtbl.(2) = mat2cell(attrtbl.(2),ones(1, nattr));
               end
               attrcarray = cell(2,nattr);
               for i = 1:nattr
                   attrname = attrtbl{i,1};
        	          attrvalue = attrtbl{i,2}{1};
                      [~, attrvalue] = obj.processAttribute(attrname, attrvalue);
                      attrcarray{1,i} = string(attrname);                      
                      attrcarray{2,i} = attrvalue;
               end
               obj.Proxy.addEvent(string(eventname), eventtime, attrcarray{:});
            else
                % NV pairs
                if rem(nin,2) ~= 0
                    error("Incorrect number of input arguments.");
                end
      	       for i = 1:2:nin
                   attrname = varargin{i};
      	          attrvalue = varargin{i+1};
                  [~, attrvalue] = obj.processAttribute(attrname, attrvalue);
                  varargin{i+1} = attrvalue;
               end
               obj.Proxy.addEvent(string(eventname), eventtime, varargin{:});
            end            
        end

    	function setStatus(obj, status, description)
            % SETSTATUS  Set the span status.
            %    SETSTATUS(SP, STATUS) sets the span status as "Ok" or
            %    "Error".
            % 
            %    SETSTATUS(SP, STATUS, DESC) also specifies a description.
            %    Description is only recorded if status is "Error".
            arguments
     	       obj
    	       status (1,:) {mustBeTextScalar}
    	       description (1,:) {mustBeTextScalar} = ""
    	    end
    	    status = validatestring(status, ["Unset", "Ok", "Error"]);
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

    methods (Static, Access=private)
        function [attrname, attrval] = processAttribute(attrname, attrval)
            % check for errors, and perform type conversion
            if ~(isStringScalar(attrname) || (ischar(attrname) && isrow(attrname)))
                error("Invalid attribute name");
            end
            if isfloat(attrval)
                attrval = double(attrval);
            elseif isinteger(attrval)
                if isa(attrval, "int8") || isa(attrval, "int16")
                    attrval = int32(attrval);
                elseif isa(attrval, "uint8") || isa(attrval, "uint16")
                    attrval = uint32(attrval);
                elseif isa(attrval, "uint64")
                    attrval = int64(attrval);
                end
            elseif ischar(attrval) && isrow(attrval)
                attrval = string(attrval);
            elseif ~(isstring(attrval) || islogical(attrval))
                error("Unsupported attribute value type");
            end
        end
    end

end
