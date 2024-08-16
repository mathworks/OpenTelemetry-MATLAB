classdef OtlpHttpSpanExporter < opentelemetry.sdk.trace.SpanExporter
% OtlpHttpSpanExporter exports spans in OpenTelemetry Protocol format via 
% HTTP. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2023-2024 The MathWorks, Inc.

    properties
        Endpoint (1,1) string = "http://localhost:4318/v1/traces" % Export destination
        Format (1,1) string = "binary"             % Data format, JSON or binary
        JsonBytesMapping (1,1) string = "hexId"  % What to convert JSON bytes to
        UseJsonName (1,1) logical = false        % Whether to use JSON name of protobuf field to set the key of JSON      
        Timeout (1,1) duration = seconds(10)     % Maximum time above which exports will abort
        HttpHeaders (1,1) dictionary = dictionary(string.empty, string.empty)  % Additional HTTP headers
    end

    properties (Access=private, Constant)
        Validator = opentelemetry.exporters.otlp.OtlpHttpValidator
    end

    methods
        function obj = OtlpHttpSpanExporter(optionnames, optionvalues)
            % OtlpHttpSpanExporter exports spans in OpenTelemetry Protocol format via HTTP.
            %    EXP = OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER
            %    creates an exporter that uses default configurations.
            %
            %    EXP =
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER(PARAM1,
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
            %    See also
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER, 
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPFILESPANEXPORTER
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            obj = obj@opentelemetry.sdk.trace.SpanExporter(...
                "libmexclass.opentelemetry.exporters.OtlpHttpSpanExporterProxy");

            validnames = ["Endpoint", "Format", "JsonBytesMapping", ...
                "UseJsonName", "Timeout", "HttpHeaders"];
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                obj.(namei) = valuei;
            end
        end

        function obj = set.Endpoint(obj, ep)
            ep = obj.Validator.validateEndpoint(ep);
            obj.Proxy.setEndpoint(ep);
            obj.Endpoint = ep;
        end

        function obj = set.Format(obj, newformat)
            newformat = obj.Validator.validateFormat(newformat);
            obj.Proxy.setFormat(newformat);
            obj.Format = newformat;
        end

        function obj = set.JsonBytesMapping(obj, jbm)
            jbm = obj.Validator.validateJsonBytesMapping(jbm);
            obj.Proxy.setJsonBytesMapping(jbm);
            obj.JsonBytesMapping = jbm;
        end

        function obj = set.UseJsonName(obj, ujn)
            ujn = obj.Validator.validateUseJsonName(ujn);
            obj.Proxy.setUseJsonName(ujn);
            obj.UseJsonName = ujn;
        end

        function obj = set.Timeout(obj, timeout)
            obj.Validator.validateTimeout(timeout);
            obj.Proxy.setTimeout(milliseconds(timeout));
            obj.Timeout = timeout;
        end

        function obj = set.HttpHeaders(obj, httpheaders)
            [headerkeys, headervalues] = obj.Validator.validateHttpHeaders(httpheaders);
            obj.Proxy.setHttpHeaders(headerkeys, headervalues);
            obj.HttpHeaders = httpheaders;
        end
    end
end
