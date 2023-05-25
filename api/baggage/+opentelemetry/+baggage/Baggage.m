classdef Baggage
% A baggage is a set of name-value pairs passed along in a context

% Copyright 2023 The MathWorks, Inc.

    properties (Dependent)
        Entries  (1,1) dictionary
    end

    properties (Access=private)
        Proxy
    end

    methods 
        function obj = Baggage(entries)
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
            arguments
     	       obj
    	       keys {mustBeVector, mustBeText}
               values {mustBeVector, mustBeText}
            end
            obj.Proxy.setEntries(string(keys(:)), string(values(:)));
        end

        function obj = deleteEntries(obj, keys)
            arguments
     	       obj
    	       keys {mustBeVector, mustBeText}
            end
            obj.Proxy.deleteEntries(string(keys(:)));
        end
    end

    methods (Access = ?opentelemetry.baggage.Context)
        function context = insertBaggage(obj, context)
            contextid = obj.Proxy.insertBaggage(context.Proxy.ID);
            contextproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.ContextProxy", "ID", contextid);
            context = opentelemetry.context.Context(contextproxy);
        end
    end
end
