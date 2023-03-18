classdef BatchSpanProcessor
% Batch span processor creates batches of spans and passes them to an exporter.

% Copyright 2023 The MathWorks, Inc.

    properties (Access=?opentelemetry.sdk.trace.TracerProvider)
        Proxy
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
            delay = -1;
            batchsize = -1;
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "MaximumQueueSize")
                    if ~isnumeric(valuei) || ~isscalar(valuei) || valuei <= 0
                        error("MaximumQueueSize must be a positive numeric scalar.");
                    end
                    qsize = double(valuei);
                elseif strcmp(namei, "ScheduledDelay")
                    if ~isduration(valuei) || ~isscalar(valuei) || valuei <= 0
                        error("ScheduledDelay must be a positive duration scalar.");
                    end
                    delay = milliseconds(valuei);
                else   % "MaximumExportBatchSize" 
                    if ~isnumeric(valuei) || ~isscalar(valuei) || valuei <= 0
                        error("MaximumExportBatchSize must be a positive numeric scalar.");
                    end
                    batchsize = double(valuei);
                end
            end
            
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.BatchSpanProcessorProxy", ...
                "ConstructorArguments", {qsize, delay, batchsize});
        end
    end
end
