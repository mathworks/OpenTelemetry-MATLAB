classdef OtlpGrpcMetricExporter < opentelemetry.sdk.metrics.MetricExporter
% OtlpGrpcMetricExporter exports Metrics in OpenTelemetry Protocol format via 
% gRPC. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Endpoint (1,1) string                           % Export destination
        UseCredentials  (1,1) logical                   % Whether to use SSL credentials
        CertificatePath (1,1) string                    % Path to .pem file for SSL encryption
        CertificateString (1,1) string                  % In-memory string representation of .pem file for SSL encryption
        Timeout (1,1) duration                          % Maximum time above which exports will abort
        HttpHeaders (1,1) dictionary                    % Additional HTTP headers
        PreferredAggregationTemporality (1,1) string    % Preferred Aggregation Temporality 
    end

    methods
        function obj = OtlpGrpcMetricExporter(optionnames, optionvalues)
            % OtlpGrpcMetricExporter exports Metrics in OpenTelemetry Protocol format via gRPC.
            %    EXP = OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCMetricEXPORTER
            %    creates an exporter that uses default configurations.
            %
            %    EXP =
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCMetricEXPORTER(PARAM1,
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
            %    See also OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPMetricEXPORTER
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["Endpoint", "UseCredentials ", "CertificatePath", ...
                "CertificateString", "Timeout", "HttpHeaders", "PreferredAggregationTemporality"];
            % set default values to empty or negative
            endpoint = "";
            usessl = false;
            certificatepath = "";
            certificatestring = "";
            timeout_millis = -1;
            headerkeys = string.empty();
            headervalues = string.empty();
            temporality = "";
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Endpoint")
                    if ~(isStringScalar(valuei) || (ischar(valuei) && isrow(valuei)))
                        error("opentelemetry:exporters:otlp:OtlpGrpcMetricExporter:EndpointNotScalarText", "Endpoint must be a scalar string.");
                    end
                    endpoint = string(valuei);
                elseif strcmp(namei, "UseCredentials ")
                    if ~((islogical(valuei) || isnumeric(valuei)) && isscalar(valuei))
                        error("opentelemetry:exporters:otlp:OtlpGrpcMetricExporter:UseCredentialsNotScalarLogical", "UseCredentials  must be a scalar logical.")
                    end
                    usessl = logical(valuei);
                elseif strcmp(namei, "CertificatePath")
                    if ~(isStringScalar(valuei) || (ischar(valuei) && isrow(valuei)))
                        error("opentelemetry:exporters:otlp:OtlpGrpcMetricExporter:CertificatePathNotScalarText", "CertificatePath must be a scalar string.");
                    end
                    certificatepath = string(valuei);
                elseif strcmp(namei, "CertificateString")
                    if ~(isStringScalar(valuei) || (ischar(valuei) && isrow(valuei)))
                        error("opentelemetry:exporters:otlp:OtlpGrpcMetricExporter:CertificateStringNotScalarText", "CertificateString must be a scalar string.");
                    end
                    certificatestring = string(valuei);
                elseif  strcmp(namei, "Timeout") 
                    if ~(isduration(valuei) && isscalar(valuei)) 
                        error("opentelemetry:exporters:otlp:OtlpGrpcMetricExporter:TimeoutNotScalarDuration", "Timeout must be a scalar duration.");
                    end
                    timeout = valuei;
                    timeout_millis = milliseconds(timeout);
                elseif strcmp(namei, "HttpHeaders")  % HttpHeaders
                    if ~isa(valuei, "dictionary")
                        error("opentelemetry:exporters:otlp:OtlpGrpcMetricExporter:HttpHeadersNotDictionary", "HttpHeaders input must be a dictionary.");
                    end
                    httpheaders = valuei;
                    headerkeys = keys(valuei);
                    headervalues = values(valuei);
                    if ~isstring(headervalues)
                        error("opentelemetry:exporters:otlp:OtlpGrpcMetricExporter:HttpHeadersNonStringValues", "HttpHeaders dictionary values must be strings.")
                    end
                elseif strcmp(namei, "PreferredAggregationTemporality")
                    temporality = validatestring(valuei, ["Cumulative", "Delta"]);
                end
            end
            
            obj = obj@opentelemetry.sdk.metrics.MetricExporter(...
                "libmexclass.opentelemetry.exporters.OtlpGrpcMetricExporterProxy", ...
                endpoint, usessl, certificatepath, certificatestring, ...
                timeout_millis, headerkeys, headervalues, temporality);

            % populate immutable properties
            [defaultendpoint, defaultcertpath, defaultcertstring, defaultmillis, defaulttemporality] = ...
                getDefaultOptionValues(obj);
            if endpoint == ""  % not specified, use default value
                obj.Endpoint = defaultendpoint;
            else
                obj.Endpoint = endpoint;
            end            
            obj.UseCredentials  = usessl;
            if certificatepath == ""  % not specified, use default value
                obj.CertificatePath = defaultcertpath;
            else
                obj.CertificatePath = certificatepath;
            end
            if certificatestring == ""  % not specified, use default value
                obj.CertificateString = defaultcertstring;
            else
                obj.CertificateString = certificatestring;
            end
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
            if temporality == ""
                obj.PreferredAggregationTemporality = defaulttemporality;
            else
                obj.PreferredAggregationTemporality = temporality;
            end
        end
    end
end
