classdef OtlpGrpcLogRecordExporter < opentelemetry.sdk.logs.LogRecordExporter
% OtlpGrpcLogRecordExporter exports log records in OpenTelemetry Protocol format via 
% gRPC. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2024 The MathWorks, Inc.

    properties 
        Endpoint (1,1) string = "http://localhost:4317"   % Export destination
        UseCredentials  (1,1) logical = false    % Whether to use SSL credentials
        CertificatePath (1,1) string = ""        % Path to .pem file for SSL encryption
        CertificateString (1,1) string = ""      % In-memory string representation of .pem file for SSL encryption
        Timeout (1,1) duration = seconds(10)     % Maximum time above which exports will abort
        HttpHeaders (1,1) dictionary = dictionary(string.empty, string.empty)  % Additional HTTP headers
    end

    properties (Access=private, Constant)
        Validator = opentelemetry.exporters.otlp.OtlpGrpcValidator
    end

    methods
        function obj = OtlpGrpcLogRecordExporter(optionnames, optionvalues)
            % OtlpGrpcLogRecordExporter exports log records in OpenTelemetry 
	    % Protocol format via gRPC.
            %    EXP = OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCLOGRECORDEXPORTER
            %    creates an exporter that uses default configurations.
            %
            %    EXP =
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCLOGRECORDEXPORTER(PARAM1,
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
            %    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPLOGRECORDEXPORTER,
	    %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPFILELOGRECORDEXPORTER
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            obj = obj@opentelemetry.sdk.logs.LogRecordExporter(...
                "libmexclass.opentelemetry.exporters.OtlpGrpcLogRecordExporterProxy");

            validnames = ["Endpoint", "UseCredentials ", "CertificatePath", ...
                "CertificateString", "Timeout", "HttpHeaders"];
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

        function obj = set.UseCredentials(obj, uc)
            uc = obj.Validator.validateUseCredentials(uc);
            obj.Proxy.setUseCredentials(uc);
            obj.UseCredentials = uc;
        end

        function obj = set.CertificatePath(obj, certpath)
            certpath = obj.Validator.validateCertificatePath(certpath);
            obj.Proxy.setCertificatePath(certpath);
            obj.CertificatePath = certpath;
        end

        function obj = set.CertificateString(obj, certstr)
            certstr = obj.Validator.validateCertificateString(certstr);
            obj.Proxy.setCertificateString(certstr);
            obj.CertificateString = certstr;
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
