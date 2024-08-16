classdef OtlpHttpValidator < opentelemetry.exporters.otlp.OtlpValidator 
% OtlpHttpValidator   Validate options inputs for OtlpHttpSpanExporter, 
% OtlpHttpMetricExporter, and OtlpHttpLogRecordExporter

% Copyright 2023-2024 The MathWorks, Inc.

    methods (Static)
        function newformat = validateFormat(newformat)
            newformat = validatestring(newformat, ["JSON", "binary"]);
        end

        function jbm = validateJsonBytesMapping(jbm)
            jbm = validatestring(jbm, ["hex", "hexId", "base64"]);
        end

        function ujn = validateUseJsonName(ujn)
            if ~((islogical(ujn) || isnumeric(ujn)) && isscalar(ujn))
                error("opentelemetry:exporters:otlp:OtlpHttpValidator:UseJsonNameNotScalarLogical", "UseJsonName must be a scalar logical.")
            end
            ujn = logical(ujn);
        end        
    end
end
