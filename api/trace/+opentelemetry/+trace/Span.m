classdef Span < handle
% A span that represents a unit of work within a trace.  

% Copyright 2023 The MathWorks, Inc.

    properties 
        Name  (1,1) string
    end

    properties (Access=private)
        Proxy
    end

    methods (Access=?opentelemetry.trace.Tracer)
        function obj = Span(proxy, spname)
            obj.Proxy = proxy;
            obj.Name = spname;
        end
    end

    methods
        function set.Name(obj, spname)
            arguments
     	       obj
    	       spname (1,:) {mustBeTextScalar}
            end
            spname = string(spname);
            obj.Proxy.updateName(spname); %#ok<MCSUP>
            obj.Name = spname;
        end

        function endSpan(obj, endtime)
            if nargin < 2
                endposixtime = NaN;
            else
                if ~(isdatetime(endtime) && isscalar(endtime) && ~isnat(endtime))
                    error("End time must be a scalar datetime that is not NaT.");
                end
                endposixtime = posixtime(endtime);
            end
            obj.Proxy.endSpan(endposixtime);
        end

        function scope = makeCurrent(obj)
            id = obj.Proxy.makeCurrent();
            scopeproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ScopeProxy", "ID", id);
    	    scope = opentelemetry.trace.Scope(scopeproxy);
        end

    	function setAttributes(obj, varargin)
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
            arguments
     	       obj
    	       status (1,:) {mustBeTextScalar}
    	       description (1,:) {mustBeTextScalar} = ""
    	    end
    	    status = validatestring(status, ["Unset", "Ok", "Error"]);
    	    obj.Proxy.setStatus(status, description);
    	end

        function context = getContext(obj)
            contextid = obj.Proxy.getContext();
            contextproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.SpanContextProxy", "ID", contextid);
            context = opentelemetry.trace.SpanContext(contextproxy);
        end

    	function tf = isRecording(obj)
            tf = obj.Proxy.isRecording();
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
