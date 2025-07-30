classdef Tracer < handle
    % A tracer that is used to create spans.

    % Copyright 2023-2025 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name    (1,1) string   % Tracer name
        Version (1,1) string   % Tracer version
        Schema  (1,1) string   % URL that documents the schema of the generated spans
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.trace.TracerProvider, ?opentelemetry.sdk.trace.TracerProvider})
        function obj = Tracer(proxy, trname, trversion, trschema)
            % Private constructor. Use getTracer method of TracerProvider
            % to create tracers.
            obj.Proxy = proxy;
            obj.Name = trname;
            obj.Version = trversion;
            obj.Schema = trschema;
        end
    end

    methods
        function span = startSpan(obj, spname, trailingnames, trailingvalues)
            % STARTSPAN Create and start a span
            %    SP = STARTSPAN(TR, NAME) starts a span with the specified
            %    span name.
            %
            %    SP = STARTSPAN(TR, NAME, PARAM1, VALUE1, PARAM2, VALUE2,
            %    ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "Context"   - Parent span contained in a context object
            %       "SpanKind"  - "server", "client", "producer",
            %                     "consumer", or "internal" (default)
            %       "StartTime" - Starting time of span specified as a
            %                     datetime. Default is the current time. If
            %                     StartTime does not have a time zone 
            %                     specified, it is interpreted as a UTC time.
            %       "Attributes" - Attribute name-value pairs specified as
            %                      a dictionary.
            %       "Links"     - Link objects that specifies relationships
            %                     with other spans.
            %
            %    See also OPENTELEMETRY.TRACE.SPAN,
            %    OPENTELEMETRY.TRACE.LINK, OPENTELEMETRY.CONTEXT.CONTEXT
            arguments
      	       obj
               spname
            end
            arguments (Repeating)
                trailingnames
                trailingvalues
            end

            import opentelemetry.common.processAttributes

            if nargin == 2
                spname = opentelemetry.common.mustBeScalarString(spname);
                id = obj.Proxy.startSpanWithNameOnly(spname);
                spanproxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.SpanProxy", "ID", id);
                span = opentelemetry.trace.Span(spanproxy, spname);
            else

                % validate the trailing names and values
                optionnames = ["Context", "SpanKind", "StartTime", "Attributes", "Links"];
                % define default values
                contextid = intmax("uint64");   % default value which means no context supplied
                spankind = "internal";
                starttime = NaN;
                attributekeys = string.empty();
                attributevalues = {};
                links = {};
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
                    elseif strcmp(namei, "SpanKind")
                        try
                            spankind = validatestring(trailingvalues{i}, ...
                                ["internal", "server", "client", "producer", "consumer"]);
                            specifyoptions = true;
                        catch
                            % invalid span kind. Ignore
                        end
                    elseif strcmp(namei, "StartTime")
                        valuei = trailingvalues{i};
                        if isdatetime(valuei) && isscalar(valuei) && ~isnat(valuei)
                            starttime = posixtime(valuei);
                            specifyoptions = true;
                        end
                    elseif strcmp(namei, "Attributes")
                        [attributekeys, attributevalues] = processAttributes(trailingvalues{i}, true);
                        specifyattributes = true;
                    elseif strcmp(namei, "Links")
                        valuei = trailingvalues{i};
                        if isa(valuei, "opentelemetry.trace.Link")
                            nlinks = numel(valuei);
                            links = cell(3,nlinks);
                            for li = 1:nlinks
                                links{1,li} = valuei(li).Target.Proxy.ID;
                                linkattrs = valuei(li).Attributes;
                                [linkattrkeys, linkattrvalues] = processAttributes(linkattrs, true);
                                links{2,li} = linkattrkeys;
                                links{3,li} = linkattrvalues;
                            end
                            links = reshape(links,1,[]);  % flatten into a row vector
                            specifyattributes = true;
                        end

                    end
                end
                spname = opentelemetry.common.mustBeScalarString(spname);
                if ~specifyoptions && ~specifyattributes
                    id = obj.Proxy.startSpanWithNameOnly(spname);
                elseif specifyoptions && ~specifyattributes
                    id = obj.Proxy.startSpanWithNameAndOptions(spname, ...
                        contextid, spankind, starttime);
                elseif ~specifyoptions && specifyattributes
                    id = obj.Proxy.startSpanWithNameAndAttributes(spname, ...
                        attributekeys, attributevalues, links{:});
                else  % specifyoptions && specifyattributes
                    id = obj.Proxy.startSpanWithNameOptionsAttributes(spname, ...
                        contextid, spankind, starttime, attributekeys, attributevalues, links{:});
                end

                spanproxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.SpanProxy", "ID", id);
        	    span = opentelemetry.trace.Span(spanproxy, spname);
            end
        end
    end

end
