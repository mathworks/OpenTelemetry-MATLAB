classdef OtlpGrpcValidator < opentelemetry.exporters.otlp.OtlpValidator 
% OtlpGrpcValidator   Validate options inputs for OtlpGrpcSpanExporter, 
% OtlpGrpcMetricExporter, and OtlpGrpcLogRecordExporter

% Copyright 2023-2024 The MathWorks, Inc.

    methods (Static)
        function uc = validateUseCredentials(uc)
            if ~((islogical(uc) || isnumeric(uc)) && isscalar(uc))
                error("opentelemetry:exporters:otlp:OtlpGrpcValidator:UseCredentialsNotScalarLogical", ...
                    "UseCredentials  must be a scalar logical.")
            end
            uc = logical(uc);
        end

        function certpath = validateCertificatePath(certpath)
            if ~(isStringScalar(certpath) || (ischar(certpath) && isrow(certpath)))
                error("opentelemetry:exporters:otlp:OtlpGrpcValidator:CertificatePathNotScalarText", ...
                    "CertificatePath must be a scalar string.");
            end
            certpath = string(certpath);
        end

        function certstr = validateCertificateString(certstr)
            if ~(isStringScalar(certstr) || (ischar(certstr) && isrow(certstr)))
                error("opentelemetry:exporters:otlp:OtlpGrpcValidator:CertificateStringNotScalarText", ...
                    "CertificateString must be a scalar string.");
            end
            certstr = string(certstr);
        end
    end
end
