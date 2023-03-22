classdef OtlpHttpSpanExporter
% OtlpHttpSpanExporter exports spans in OpenTelemetry Protocol format via 
% HTTP. By default, it exports to the default address of the OpenTelemetry
% Collector.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess=?opentelemetry.sdk.trace.SpanProcessor)
        Proxy
    end

    properties (SetAccess=immutable)
        Endpoint (1,1) string
        Timeout (1,1) duration
    end

    methods
        function obj = OtlpHttpSpanExporter(optionnames, optionvalues)
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["Endpoint", "Timeout"];
            % set default values to empty or negative
            endpoint = "";
            timeout_millis = -1;
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Endpoint")
                    if ~(isStringScalar(valuei) || (ischar(valuei) && isrow(valuei)))
                        error("Endpoint must be a scalar string.");
                    end
                    endpoint = string(valuei);
                else   % "Timeout" 
                    if ~(isduration(valuei) && isscalar(valuei)) 
                        error("Timeout must be a scalar duration.");
                    end
                    timeout = valuei;
                    timeout_millis = milliseconds(timeout);
                end
            end
            
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.exporters.OtlpHttpSpanExporterProxy", ...
                "ConstructorArguments", {endpoint, timeout_millis});

            % populate immutable properties
            if endpoint == "" || timeout_millis < 0
                [defaultendpoint, defaultmillis] = obj.Proxy.getDefaultOptionValues();
            end
            if endpoint == ""  % not specified, use default value
                obj.Endpoint = defaultendpoint;
            else
                obj.Endpoint = endpoint;
            end
            if timeout_millis < 0  % not specified, use default value
                obj.Timeout = milliseconds(defaultmillis);
            else
                obj.Timeout = timeout;
            end
        end
    end
end
