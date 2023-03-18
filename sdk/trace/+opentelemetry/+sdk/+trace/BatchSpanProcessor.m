classdef BatchSpanProcessor
% Batch span processor creates batches of spans and passes them to an exporter.

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess=?opentelemetry.sdk.trace.TracerProvider)
        Proxy
    end

    properties (SetAccess=immutable)
        MaximumQueueSize (1,1) double
        ScheduledDelay (1,1) duration
        MaximumExportBatchSize (1,1) double
    end

    methods
        function obj = BatchSpanProcessor(optionnames, optionvalues)
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["MaximumQueueSize", "ScheduledDelay", "MaximumExportBatchSize"];
            % set default values to negative
            qsize = -1;
            delaymillis = -1;
            batchsize = -1;
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "MaximumQueueSize")
                    if ~isnumeric(valuei) || ~isscalar(valuei) || valuei <= 0 || ...
                            round(valuei) ~= valuei
                        error("MaximumQueueSize must be a scalar positive integer.");
                    end
                    qsize = double(valuei);
                elseif strcmp(namei, "ScheduledDelay")
                    if ~isduration(valuei) || ~isscalar(valuei) || valuei <= 0
                        error("ScheduledDelay must be a positive duration scalar.");
                    end
                    delay = valuei;
                    delaymillis = milliseconds(valuei);
                else   % "MaximumExportBatchSize" 
                    if ~isnumeric(valuei) || ~isscalar(valuei) || valuei <= 0 || ...
                            round(valuei) ~= valuei
                        error("MaximumExportBatchSize must be a scalar positive integer.");
                    end
                    batchsize = double(valuei);
                end
            end
            
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.BatchSpanProcessorProxy", ...
                "ConstructorArguments", {qsize, delaymillis, batchsize});

            % populate immutable properties
            if qsize < 0 || delaymillis < 0 || batchsize < 0
                [defaultqsize, defaultmillis, defaultbatchsize] = obj.Proxy.getDefaultOptionValues();
            end
            if qsize < 0  % not specified, use default value
                obj.MaximumQueueSize = defaultqsize;
            else
                obj.MaximumQueueSize = qsize;
            end
            if delaymillis < 0  % not specified, use default value
                obj.ScheduledDelay = milliseconds(defaultmillis);
            else
                obj.ScheduledDelay = delay;
            end
            if batchsize < 0  % not specified, use default value
                obj.MaximumExportBatchSize = defaultbatchsize;
            else
                obj.MaximumExportBatchSize = batchsize;
            end
        end
    end
end
