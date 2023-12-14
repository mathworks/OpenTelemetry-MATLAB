classdef OtlpValidator 
% OtlpValidator   Validate export options

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function ep = validateEndpoint(ep)
            if ~(isStringScalar(ep) || (ischar(ep) && isrow(ep)))
                error("opentelemetry:exporters:otlp:OtlpValidator:EndpointNotScalarText", ...
                    "Endpoint must be a scalar string.");
            end
            ep = string(ep);
        end
        
        function validateTimeout(timeout)
            if ~(isduration(timeout) && isscalar(timeout))
                error("opentelemetry:exporters:otlp:OtlpValidator:TimeoutNotScalarDuration", ...
                    "Timeout must be a scalar duration.");
            end
        end

        function [headerkeys, headervalues] = validateHttpHeaders(httpheaders)
            if ~isa(httpheaders, "dictionary")
                error("opentelemetry:exporters:otlp:OtlpValidator:HttpHeadersNotDictionary", ...
                    "HttpHeaders input must be a dictionary.");
            end
            headerkeys = keys(httpheaders);
            headervalues = values(httpheaders);
            if ~isstring(headervalues)
                error("opentelemetry:exporters:otlp:OtlpValidator:HttpHeadersNonStringValues", ...
                    "HttpHeaders dictionary values must be strings.")
            end
        end
    end
end
