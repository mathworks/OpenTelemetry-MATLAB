classdef OtlpGrpcSpanExporter < opentelemetry.sdk.trace.SpanExporter
% OtlpGrpcSpanExporter exports spans in OpenTelemetry Protocol format via 
% gRPC. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2023 The MathWorks, Inc.

    properties 
        Endpoint (1,1) string = "http://localhost:4317"   % Export destination
        UseCredentials  (1,1) logical = false    % Whether to use SSL credentials
        CertificatePath (1,1) string = ""        % Path to .pem file for SSL encryption
        CertificateString (1,1) string = ""      % In-memory string representation of .pem file for SSL encryption
        Timeout (1,1) duration = seconds(10)     % Maximum time above which exports will abort
        HttpHeaders (1,1) dictionary = dictionary(string.empty, string.empty)  % Additional HTTP headers
    end

    methods
        function obj = OtlpGrpcSpanExporter(optionnames, optionvalues)
            % OtlpGrpcSpanExporter exports spans in OpenTelemetry Protocol format via gRPC.
            %    EXP = OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER
            %    creates an exporter that uses default configurations.
            %
            %    EXP =
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCSPANEXPORTER(PARAM1,
            %    VALUE1, PARAM2, VALUE2, ...) specifies optional parameter 
            %    name/value pairs. Parameters are:
            %       "Endpoint"          - Endpoint to export to
            %       "UseCredentials"    - Whether to use SSL credentials.
            %                             Default is false. If true, use
            %                             .pem file specified in
            %                             "CertificatePath" or
            %                             "CertificateString".
            %       "CertificatePath"   - Path to .pem file for SSL encryption
            %       "CertificateString" - .pem file specified in memory as
            %                             a string
            %       "Timeout"           - Maximum time above which exports 
            %                             will abort
            %       "HTTPHeaders"       - Additional HTTP Headers
            %
            %    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPSPANEXPORTER
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            obj = obj@opentelemetry.sdk.trace.SpanExporter(...
                "libmexclass.opentelemetry.exporters.OtlpGrpcSpanExporterProxy");

            validnames = ["Endpoint", "UseCredentials ", "CertificatePath", ...
                "CertificateString", "Timeout", "HttpHeaders"];
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                obj.(namei) = valuei;                
            end
        end

        function obj = set.Endpoint(obj, ep)
            if ~(isStringScalar(ep) || (ischar(ep) && isrow(ep)))
                error("opentelemetry:exporters:otlp:OtlpGrpcSpanExporter:EndpointNotScalarText", "Endpoint must be a scalar string.");
            end
            ep = string(ep);
            obj.Proxy.setEndpoint(ep);
            obj.Endpoint = ep;
        end

        function obj = set.UseCredentials(obj, uc)
            if ~((islogical(uc) || isnumeric(uc)) && isscalar(uc))
                error("opentelemetry:exporters:otlp:OtlpGrpcSpanExporter:UseCredentialsNotScalarLogical", "UseCredentials  must be a scalar logical.")
            end
            uc = logical(uc);
            obj.Proxy.setUseCredentials(uc);
            obj.UseCredentials = uc;
        end

        function obj = set.CertificatePath(obj, certpath)
            if ~(isStringScalar(certpath) || (ischar(certpath) && isrow(certpath)))
                error("opentelemetry:exporters:otlp:OtlpGrpcSpanExporter:CertificatePathNotScalarText", "CertificatePath must be a scalar string.");
            end
            certpath = string(certpath);
            obj.Proxy.setCertificatePath(certpath);
            obj.CertificatePath = certpath;
        end

        function obj = set.CertificateString(obj, certstr)
            if ~(isStringScalar(certstr) || (ischar(certstr) && isrow(certstr)))
                error("opentelemetry:exporters:otlp:OtlpGrpcSpanExporter:CertificateStringNotScalarText", "CertificateString must be a scalar string.");
            end
            certstr = string(certstr);
            obj.Proxy.setCertificateString(certstr);
            obj.CertificateString = certstr;
        end

        function obj = set.Timeout(obj, timeout)
            if ~(isduration(timeout) && isscalar(timeout))
                error("opentelemetry:exporters:otlp:OtlpGrpcSpanExporter:TimeoutNotScalarDuration", "Timeout must be a scalar duration.");
            end
            obj.Proxy.setTimeout(milliseconds(timeout));
            obj.Timeout = timeout;
        end

        function obj = set.HttpHeaders(obj, httpheaders)
            if ~isa(httpheaders, "dictionary")
                error("opentelemetry:exporters:otlp:OtlpGrpcSpanExporter:HttpHeadersNotDictionary", "HttpHeaders input must be a dictionary.");
            end
            headerkeys = keys(httpheaders);
            headervalues = values(httpheaders);
            if ~isstring(headervalues)
                error("opentelemetry:exporters:otlp:OtlpGrpcSpanExporter:HttpHeadersNonStringValues", "HttpHeaders dictionary values must be strings.")
            end
            obj.Proxy.setHttpHeaders(headerkeys, headervalues);
            obj.HttpHeaders = httpheaders;
        end
    end
end
