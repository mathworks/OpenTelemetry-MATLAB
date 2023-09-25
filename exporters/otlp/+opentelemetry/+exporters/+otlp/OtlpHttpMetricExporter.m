classdef OtlpHttpMetricExporter < opentelemetry.sdk.metrics.MetricExporter
% OtlpHttpMetricExporter exports Metrics in OpenTelemetry Protocol format via 
% HTTP. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Endpoint (1,1) string           % Export destination
        Format (1,1) string             % Data format, JSON or binary
        JsonBytesMapping (1,1) string   % What to convert JSON bytes to
        UseJsonName (1,1) logical       % Whether to use JSON name of protobuf field to set the key of JSON 
        Timeout (1,1) duration          % Maximum time above which exports will abort
        HttpHeaders (1,1) dictionary    % Additional HTTP headers
    end

    methods
        function obj = OtlpHttpMetricExporter(optionnames, optionvalues)
            % OtlpHttpMetricExporter exports Metrics in OpenTelemetry Protocol format via HTTP.
            %    EXP = OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMetricEXPORTER
            %    creates an exporter that uses default configurations.
            %
            %    EXP =
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMetricEXPORTER(PARAM1,
            %    VALUE1, PARAM2, VALUE2, ...) specifies optional parameter 
            %    name/value pairs. Parameters are:
            %       "Endpoint"          - Endpoint to export to
            %       "Format"            - Data format: "JSON" (default) or "binary"
            %       "JsonBytesMapping"  - What to convert JSON bytes to. Supported
            %                             values are "hex", "hexId" (default), and
            %                             "base64". Default "hexId"
            %                             converts to base 64 except for IDs
            %                             which are converted to hexadecimals.
            %       "UseJsonName"       - Whether to use JSON name of protobuf 
            %                             field to set the key of JSON
            %       "Timeout"           - Maximum time above which exports 
            %                             will abort
            %       "HTTPHeaders"       - Additional HTTP Headers
            %
            %    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCMetricEXPORTER
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
                        error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:EndpointNotScalarText", "Endpoint must be a scalar string.");
                    end
                    endpoint = string(valuei);
                elseif strcmp(namei, "Format")
                    dataformat = validatestring(valuei, ["JSON", "binary"]);
                elseif strcmp(namei, "JsonBytesMapping")
                    jsonbytesmapping = validatestring(valuei, ["hex", "hexId", "base64"]);
                elseif strcmp(namei, "UseJsonName")
                    if ~((islogical(valuei) || isnumeric(valuei)) && isscalar(valuei))
                        error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:UseJsonNameNotScalarLogical", "UseJsonName must be a scalar logical.")
                    end
                    usejsonname = logical(valuei);
                elseif  strcmp(namei, "Timeout") 
                    if ~(isduration(valuei) && isscalar(valuei)) 
                        error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:TimeoutNotScalarDuration", "Timeout must be a scalar duration.");
                    end
                    timeout = valuei;
                    timeout_millis = milliseconds(timeout);
                else  % HttpHeaders
                    if ~isa(valuei, "dictionary")
                        error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:HttpHeadersNotDictionary", "HttpHeaders input must be a dictionary.");
                    end
                    httpheaders = valuei;
                    headerkeys = keys(valuei);
                    headervalues = values(valuei);
                    if ~isstring(headervalues)
                        error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:HttpHeadersNonStringValues", "HttpHeaders dictionary values must be strings.")
                    end
                end
            end
            
            obj = obj@opentelemetry.sdk.metrics.MetricExporter(...
                "libmexclass.opentelemetry.exporters.OtlpHttpMetricExporterProxy", ...
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
