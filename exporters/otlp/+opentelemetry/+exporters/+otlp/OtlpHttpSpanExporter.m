classdef OtlpHttpSpanExporter < opentelemetry.sdk.trace.SpanExporter
% OtlpHttpSpanExporter exports spans in OpenTelemetry Protocol format via 
% HTTP. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Endpoint (1,1) string
        Format (1,1) string
        JsonBytesMapping (1,1) string
        UseJsonName (1,1) logical
        Timeout (1,1) duration
        HttpHeaders (1,1) dictionary
    end

    methods
        function obj = OtlpHttpSpanExporter(optionnames, optionvalues)
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["Endpoint", "Format", "JsonBytesMapping", ...
                "UseJsonName", "Timeout", "HttpHeaders"];
            % set default values to empty or negative
            endpoint = "";
            dataformat = "";
            jsonbytesmapping = "";
            usejsonname = false;
            timeout_millis = -1;
            headerkeys = string.empty();
            headervalues = string.empty();
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Endpoint")
                    if ~(isStringScalar(valuei) || (ischar(valuei) && isrow(valuei)))
                        error("Endpoint must be a scalar string.");
                    end
                    endpoint = string(valuei);
                elseif strcmp(namei, "Format")
                    dataformat = validatestring(valuei, ["JSON", "binary"]);
                elseif strcmp(namei, "JsonBytesMapping")
                    jsonbytesmapping = validatestring(valuei, ["hex", "hexId", "base64"]);
                elseif strcmp(namei, "UseJsonName")
                    if ~((islogical(valuei) || isnumeric(valuei)) && isscalar(valuei))
                        error("UseJsonName must be a scalar logical.")
                    end
                    usejsonname = logical(valuei);
                elseif  strcmp(namei, "Timeout") 
                    if ~(isduration(valuei) && isscalar(valuei)) 
                        error("Timeout must be a scalar duration.");
                    end
                    timeout = valuei;
                    timeout_millis = milliseconds(timeout);
                else  % HttpHeaders
                    if ~isa(valuei, "dictionary")
                        error("HttpHeaders input must be a dictionary.");
                    end
                    httpheaders = valuei;
                    headerkeys = keys(valuei);
                    headervalues = values(valuei);
                    if ~isstring(headervalues)
                        error("HttpHeaders dictionary values must be strings.")
                    end
                end
            end
            
            obj = obj@opentelemetry.sdk.trace.SpanExporter(...
                "libmexclass.opentelemetry.exporters.OtlpHttpSpanExporterProxy", ...
                endpoint, dataformat, jsonbytesmapping, usejsonname, ...
                timeout_millis, headerkeys, headervalues);

            % populate immutable properties
            if endpoint == "" || dataformat == "" || jsonbytesmapping == "" || ...
                    timeout_millis < 0
                [defaultendpoint, defaultformat, defaultmapping, defaultmillis] = ...
                    getDefaultOptionValues(obj);
            end
            if endpoint == ""  % not specified, use default value
                obj.Endpoint = defaultendpoint;
            else
                obj.Endpoint = endpoint;
            end
            if dataformat == ""  % not specified, use default value
                obj.Format = defaultformat;
            else
                obj.Format = dataformat;
            end
            if jsonbytesmapping == ""  % not specified, use default value
                obj.JsonBytesMapping = defaultmapping;
            else
                obj.JsonBytesMapping = jsonbytesmapping;
            end
            obj.UseJsonName = usejsonname;
            if timeout_millis < 0  % not specified, use default value
                obj.Timeout = milliseconds(defaultmillis);
            else
                obj.Timeout = timeout;
            end
            if isempty(headerkeys)  % not specified, return empty dictionary
                obj.HttpHeaders = dictionary(headerkeys, headervalues);
            else
                obj.HttpHeaders = httpheaders;
            end
        end
    end
end
