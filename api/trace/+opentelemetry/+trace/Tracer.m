classdef Tracer < handle
    % A tracer that is used to create spans.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name    (1,1) string
        Version (1,1) string
        Schema  (1,1) string
    end

    properties (Access=private)
        Proxy
    end

    methods (Access={?opentelemetry.trace.TracerProvider, ?opentelemetry.sdk.trace.TracerProvider})
        function obj = Tracer(proxy, trname, trversion, trschema)
            obj.Proxy = proxy;
            obj.Name = trname;
            obj.Version = trversion;
            obj.Schema = trschema;
        end
    end

    methods
        function span = startSpan(obj, spname, trailingnames, trailingvalues)
    	    arguments
     	       obj
    	       spname (1,:) {mustBeTextScalar}
            end
            arguments (Repeating)
                trailingnames (1,:) {mustBeTextScalar}
                trailingvalues
            end
            % validate the trailing names and values
            optionnames = ["Context", "SpanKind", "Attributes"];
            % define default values
            contextid = intmax("uint64");   % default value which means no context supplied
            spankind = "internal";
            attributekeys = string.empty();
            attributevalues = {};
            % Loop through Name-Value pairs
            for i = 1:length(trailingnames)
                namei = validatestring(trailingnames{i}, optionnames);
                if strcmp(namei, "Context")                    
                    context = trailingvalues{i};
                    if ~isa(context, "opentelemetry.trace.SpanContext")
                        error("Context must be an opentelemetry.trace.SpanContext object");
                    end
                    contextid = context.Proxy.ID;
                elseif strcmp(namei, "SpanKind")
                    spankind = validatestring(trailingvalues{i}, ...
                        ["internal", "server", "client", "producer", "consumer"]);
                elseif strcmp(namei, "Attributes")
                    valuei = trailingvalues{i};
                    if ~isa(valuei, "dictionary")
                        error("Attibutes input must be a dictionary.");
                    end
                    attributekeys = keys(valuei);
                    attributevalues = values(valuei,"cell");
                    % collapse one level of cells, as this may be due to
                    % a behavior of dictionary.values
                    if all(cellfun(@iscell, attributevalues))
                        attributevalues = [attributevalues{:}];
                    end
                end
            end
            spname = string(spname);
            id = obj.Proxy.startSpan(spname, contextid, spankind, ...
                attributekeys, attributevalues);
            spanproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.SpanProxy", "ID", id);
    	    span = opentelemetry.trace.Span(spanproxy, spname);
        end
    end

end
