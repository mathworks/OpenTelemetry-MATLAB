classdef OtlpHttpMetricExporter < opentelemetry.sdk.metrics.MetricExporter
% OtlpHttpMetricExporter exports metrics in OpenTelemetry Protocol format via 
% HTTP. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2023 The MathWorks, Inc.

    properties
        Endpoint (1,1) string = "http://localhost:4318/v1/metrics"  % Export destination
        Format (1,1) string = "JSON"                % Data format, JSON or binary
        JsonBytesMapping (1,1) string = "hexId"     % What to convert JSON bytes to
        UseJsonName (1,1) logical = false           % Whether to use JSON name of protobuf field to set the key of JSON 
        Timeout (1,1) duration = seconds(10)        % Maximum time above which exports will abort
        HttpHeaders (1,1) dictionary = dictionary(string.empty, string.empty)  % Additional HTTP headers
        PreferredAggregationTemporality (1,1) string = "cumulative"   % Preferred Aggregation Temporality
    end

    methods
        function obj = OtlpHttpMetricExporter(optionnames, optionvalues)
            % OtlpHttpMetricExporter exports metrics in OpenTelemetry Protocol format via HTTP.
            %    EXP = OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMETRICEXPORTER
            %    creates an exporter that uses default configurations.
            %
            %    EXP =
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMETRICEXPORTER(PARAM1,
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
            %       "PreferredAggregationTemporality"  
            %                           - An aggregation temporality of 
            %                           - delta or cumulative
            %
            %    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCMETRICEXPORTER
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            obj = obj@opentelemetry.sdk.metrics.MetricExporter(...
                "libmexclass.opentelemetry.exporters.OtlpHttpMetricExporterProxy");

            validnames = ["Endpoint", "Format", "JsonBytesMapping", ...
                "UseJsonName", "Timeout", "HttpHeaders", "PreferredAggregationTemporality"];
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                obj.(namei) = valuei;
            end
        end

        function obj = set.Endpoint(obj, ep)
            if ~(isStringScalar(ep) || (ischar(ep) && isrow(ep)))
                error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:EndpointNotScalarText", "Endpoint must be a scalar string.");
            end
            ep = string(ep);
            obj.Proxy.setEndpoint(ep);
            obj.Endpoint = ep;
        end

        function obj = set.Format(obj, newformat)
            newformat = validatestring(newformat, ["JSON", "binary"]);
            obj.Proxy.setFormat(newformat);
            obj.Format = newformat;
        end

        function obj = set.JsonBytesMapping(obj, jbm)
            jbm = validatestring(jbm, ["hex", "hexId", "base64"]);
            obj.Proxy.setJsonBytesMapping(jbm);
            obj.JsonBytesMapping = jbm;
        end

        function obj = set.UseJsonName(obj, ujn)
            if ~((islogical(ujn) || isnumeric(ujn)) && isscalar(ujn))
                error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:UseJsonNameNotScalarLogical", "UseJsonName must be a scalar logical.")
            end
            ujn = logical(ujn);
            obj.Proxy.setUseJsonName(ujn);
            obj.UseJsonName = ujn;
        end

        function obj = set.Timeout(obj, timeout)
            if ~(isduration(timeout) && isscalar(timeout))
                error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:TimeoutNotScalarDuration", "Timeout must be a scalar duration.");
            end
            obj.Proxy.setTimeout(milliseconds(timeout));
            obj.Timeout = timeout;
        end

        function obj = set.HttpHeaders(obj, httpheaders)
            if ~isa(httpheaders, "dictionary")
                error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:HttpHeadersNotDictionary", "HttpHeaders input must be a dictionary.");
            end
            headerkeys = keys(httpheaders);
            headervalues = values(httpheaders);
            if ~isstring(headervalues)
                error("opentelemetry:exporters:otlp:OtlpHttpMetricExporter:HttpHeadersNonStringValues", "HttpHeaders dictionary values must be strings.")
            end
            obj.Proxy.setHttpHeaders(headerkeys, headervalues);
            obj.HttpHeaders = httpheaders;
        end

        function obj = set.PreferredAggregationTemporality(obj, temporality)
            temporality = validatestring(temporality, ["cumulative", "delta"]);
            obj.Proxy.setTemporality(temporality);
            obj.PreferredAggregationTemporality = temporality;
        end
    end
end