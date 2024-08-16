classdef OtlpFileValidator 
% OtlpFileValidator   Validate options inputs for OtlpFileSpanExporter, 
% OtlpFileMetricExporter, and OtlpFileLogRecordExporter

% Copyright 2024 The MathWorks, Inc.

    methods (Static)
        function name = validateName(name, paramname)
            if ~(isStringScalar(name) || (ischar(name) && isrow(name)))
                error("opentelemetry:exporters:otlp:OtlpFileValidator:NameNotScalarText", ...
                    paramname + " must be a scalar string or a char row.");
            end
            name = string(name);
        end

        function validateFlushInterval(interval)
            if ~(isduration(interval) && isscalar(interval))
                error("opentelemetry:exporters:otlp:OtlpFileValidator:FlushIntervalNotScalarDuration", ...
                    "FlushInterval must be a scalar duration.");
            end
        end

        function value = validateScalarPositiveInteger(value, paramname)
            if ~((islogical(value) || isnumeric(value)) && isscalar(value) && ...
                    value > 0 && round(value) == value)
                error("opentelemetry:exporters:otlp:OtlpFileValidator:NotScalarPositiveInteger", ...
                    paramname + " must be a scalar positive integer.")
            end
            value = double(value);
        end      
    end
end
