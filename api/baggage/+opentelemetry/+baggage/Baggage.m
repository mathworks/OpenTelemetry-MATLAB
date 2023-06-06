classdef Baggage
% A baggage is a set of name-value pairs passed along in a context

% Copyright 2023 The MathWorks, Inc.

    properties (Dependent)
        Entries  (1,1) dictionary   % Name-value pairs stored in baggage
    end

    properties (Access=private)
        Proxy    % Proxy object to interface C++ code
    end

    methods 
        function obj = Baggage(entries)
            % Object that stores name-value pairs, to be passed along in a context
            %    B = OPENTELEMETRY.BAGGAGE.BAGGAGE creates an empty baggage
            %    object.
            %
            %    B = OPENTELEMETRY.BAGGAGE.BAGGAGE(ENTRIES) populate
            %    baggage with the name-value pairs stored in dictionary
            %    ENTRIES. The keys and values in ENTRIES must both be
            %    strings.
            %
            %    See also
            %    OPENTELEMETRY.BAGGAGE.PROPAGATION.BAGGAGEPROPAGATOR
            if nargin < 1
                entries = dictionary(strings(0,1),strings(0,1));
            end
            if isa(entries, "opentelemetry.context.Context")
                % called from opentelemetry.baggage.Context.extractBaggage
                context = entries;
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.BaggageProxy", ...
                    "ConstructorArguments", {context.Proxy.ID});
            else   % input is baggage entries
                if isa(entries, "dictionary")
                    [keytype, valuetype] = types(entries);
        		    % baggage keys and values must be strings
                    if keytype == "string" && valuetype == "string"
                        obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                            "libmexclass.opentelemetry.BaggageProxy", ...
                            "ConstructorArguments", {keys(entries), values(entries)});
                        return
                    end
                end
                % if it get here, it is an error condition
                error("Input must be a dictionary with string keys and string values.");
            end
        end

        function entries = get.Entries(obj)
            [keys, values] = obj.Proxy.getAllEntries();
            entries = dictionary(keys, values);
        end

        function obj = set.Entries(obj, entries)
            arguments
     	       obj
    	       entries (1,1) dictionary
            end
            newkeys = keys(entries);
            currentries = obj.Entries;
            currkeys = keys(currentries);

            % check which entries need to be deleted, inserted, or set
            deletekeys = setdiff(currkeys, newkeys);
            insertkeys = setdiff(newkeys, currkeys);
            commonkeys = intersect(currkeys, newkeys);
            % set only keys with modified values, and new keys
            setkeys = [commonkeys(entries(commonkeys) ~= currentries(commonkeys)); ...
                insertkeys];
            
            % make the changes
            obj.Proxy.setEntries(setkeys, entries(setkeys));
            obj.Proxy.deleteEntries(deletekeys);
        end

        function obj = setEntries(obj, keys, values)
            % SETENTRIES Set entry values
            %    B = SETENTRIES(B, KEYS, VALUES) sets the values associated
            %    with keys KEYS. Both KEYS and VALUES must be string arrays
            %    or cell array of character vectors of the same length. If
            %    a key is not in baggage B, the key will be added.
            %
            %    See also DELETEENTRIES
            arguments
     	       obj
    	       keys {mustBeVector, mustBeText}
               values {mustBeVector, mustBeText}
            end
            if length(keys) ~= length(values)
                error("Keys and values must be the same length.")
            end
            obj.Proxy.setEntries(string(keys(:)), string(values(:)));
        end

        function obj = deleteEntries(obj, keys)
            % DELETEENTRIES Delete entries from baggage
            %    B = DELETEENTRIES(B, KEYS) delete the entries associated
            %    with keys KEYS. If a key is not in baggage B, it will be
            %    ignored.
            %
            %    See also SETENTRIES
            arguments
     	       obj
    	       keys {mustBeVector, mustBeText}
            end
            obj.Proxy.deleteEntries(string(keys(:)));
        end

        function context = insertBaggage(obj, context)
            % INSERTBAGGAGE Insert baggage into a context
            %    NEWCTXT = INSERTBAGGAGE(B) inserts baggage B into the
            %    current context and returns a new context NEWCTXT.
            %
            %    NEWCTXT = INSERTBAGGAGE(B, CTXT) specifies the context to
            %    insert into.
            %
            %    See also OPENTELEMETRY.BAGGAGE.CONTEXT.EXTRACTBAGGAGE
            if nargin < 2
                context = opentelemetry.context.getCurrentContext();
            end
            contextid = obj.Proxy.insertBaggage(context.Proxy.ID);
            contextproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ContextProxy", "ID", contextid);
            context = opentelemetry.context.Context(contextproxy);
        end
    end
end
