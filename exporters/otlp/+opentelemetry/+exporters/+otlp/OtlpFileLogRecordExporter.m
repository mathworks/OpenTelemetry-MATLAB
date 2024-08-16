classdef OtlpFileLogRecordExporter < opentelemetry.sdk.logs.LogRecordExporter
% OtlpFileLogRecordExporter exports log records in OpenTelemetry Protocol format to
% one or more files. 

% Copyright 2024 The MathWorks, Inc.

    properties
        FileName (1,1) string = "logs-%N.jsonl"         % Output file name
        AliasName (1,1) string = "logs-latest.jsonl"    % Alias file name, which is the latest file in rotation     
        FlushInterval (1,1) duration = seconds(30)      % Time interval between log record exports
        FlushRecordCount (1,1) double = 256             % Maximum number of records before exporting
        MaxFileSize (1,1) double = 20971520             % Maximum output file size
        MaxFileCount (1,1) double = 10                  % Maximum number of output files, written to in rotation.
    end

    properties (Access=private, Constant)
        Validator = opentelemetry.exporters.otlp.OtlpFileValidator
    end

    methods
        function obj = OtlpFileLogRecordExporter(optionnames, optionvalues)
            % OtlpFileLogRecordExporter exports log records in OpenTelemetry 
            % Protocol format to one or more files.
            %    EXP = OPENTELEMETRY.EXPORTERS.OTLP.OTLPFILELOGRECORDEXPORTER
            %    creates an exporter that uses default configurations.
            %
            %    EXP =
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPFILELOGRECORDEXPORTER(PARAM1,
            %    VALUE1, PARAM2, VALUE2, ...) specifies optional parameter 
            %    name/value pairs. Parameters are:
            %       "FileName"          - Output file name. Can contain
            %                             pattern placeholders. Default
            %                             name is "logs-%N.jsonl"
            %       "AliasName"         - Alias file name, which is the 
            %                             latest file in rotation. Can
            %                             contain pattern placeholders.
            %                             Default name is "logs-latest.jsonl"
            %       "FlushInterval"     - Time interval between log record
            %                             exports, represented as a
            %                             duration. Default is 30 seconds.
            %       "FlushRecordCount"  - Maximum number of records before
            %                             exporting. When the number of 
            %                             records exceed this value, an 
            %                             export will be started. Default
            %                             is 256.
            %       "MaxFileSize"       - Maximum output file size
            %       "MaxFileCount"      - Maximum number of output files, 
            %                             written to in rotation. Default
            %                             is 10.
            %
            %    Supported pattern placeholders in FileName and AliasName are:
            %       %Y:  year as a 4 digit decimal number
            %       %y:  last 2 digits of year as a decimal number (range [00,99])
            %       %m:  month as a decimal number (range [01,12])
            %       %j:  day of the year as a decimal number (range [001,366])
            %       %d:  day of the month as a decimal number (range [01,31])
            %       %w:  weekday as a decimal number, where Sunday is 0 (range [0-6])
            %       %H:  hour as a decimal number, 24 hour clock (range [00-23])
            %       %I:  hour as a decimal number, 12 hour clock (range [01,12])
            %       %M:  minute as a decimal number (range [00,59])
            %       %S:  second as a decimal number (range [00,60])
            %       %F:  equivalent to "%Y-%m-%d" (the ISO 8601 date format)
            %       %T:  equivalent to "%H:%M:%S" (the ISO 8601 time format)
            %       %R:  equivalent to "%H:%M"
            %       %N:  rotate index, starting from 0
            %       %n:  rotate index, starting from 1   
            %
            %    See also
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPHTTPLOGRECORDEXPORTER,
            %    OPENTELEMETRY.EXPORTERS.OTLP.OTLPGRPCLOGRECORDEXPORTER
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            obj = obj@opentelemetry.sdk.logs.LogRecordExporter(...
                "libmexclass.opentelemetry.exporters.OtlpFileLogRecordExporterProxy");

            validnames = ["FileName", "AliasName", "FlushInterval", ...
                "FlushRecordCount", "MaxFileSize", "MaxFileCount"];
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                obj.(namei) = valuei;
            end
        end

        function obj = set.FileName(obj, fn)
            fn = obj.Validator.validateName(fn, "FileName");
            obj.Proxy.setFileName(fn);
            obj.FileName = fn;
        end

        function obj = set.AliasName(obj, alias)
            alias = obj.Validator.validateName(alias, "AliasName");
            obj.Proxy.setAliasName(alias);
            obj.AliasName = alias;
        end

        function obj = set.FlushInterval(obj, interval)
            obj.Validator.validateFlushInterval(interval);
            obj.Proxy.setFlushInterval(milliseconds(interval));
            obj.FlushInterval = interval;
        end

        function obj = set.FlushRecordCount(obj, count)
            count = obj.Validator.validateScalarPositiveInteger(count, "FlushRecordCount");
            obj.Proxy.setFlushRecordCount(count);
            obj.FlushRecordCount = count;
        end

        function obj = set.MaxFileSize(obj, maxsize)
            maxsize = obj.Validator.validateScalarPositiveInteger(maxsize, "MaxFileSize");
            obj.Proxy.setMaxFileSize(maxsize);
            obj.MaxFileSize = maxsize;
        end

        function obj = set.MaxFileCount(obj, maxfilecount)
            maxfilecount = obj.Validator.validateScalarPositiveInteger(maxfilecount, "MaxFileCount");
            obj.Proxy.setMaxFileCount(maxfilecount);
            obj.MaxFileCount = maxfilecount;
        end
    end
end
