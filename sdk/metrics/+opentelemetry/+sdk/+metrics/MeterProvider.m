classdef MeterProvider < opentelemetry.metrics.MeterProvider & handle
    % An SDK implementation of meter provider, which stores a set of configurations used
    % in a metrics system.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
        isShutdown (1,1) logical = false
    end


    properties (Access=public)
        MetricReader
    end

    properties (Access=public)
        Resource
    end

    methods
        function obj = MeterProvider(reader, optionnames, optionvalues)
            % SDK implementation of tracer provider
            %    MP = OPENTELEMETRY.SDK.METRICS.METERPROVIDER creates a meter 
            %    provider that uses a periodic exporting metric reader and default configurations.
            %
            %    MP = OPENTELEMETRY.SDK.METRICS.METERPROVIDER(R) uses metric
            %    reader R. Currently, the only supported metric reader is the periodic 
	    %    exporting metric reader.
            %
            %    TP = OPENTELEMETRY.SDK.METRICS.METERPROVIDER(R, PARAM1, VALUE1, 
            %    PARAM2, VALUE2, ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "View"        - View object used to customize collected metrics.
            %       "Resource"    - Additional resource attributes.
            %                       Specified as a dictionary.
            %
            %    See also OPENTELEMETRY.SDK.METRICS.PERIODICEXPORTINGMETRICREADER
            %    OPENTELEMETRY.SDK.METRICS.VIEW

            arguments
     	        reader {mustBeA(reader, ["opentelemetry.sdk.metrics.PeriodicExportingMetricReader", ...
                   "libmexclass.proxy.Proxy"])} = ...
    		            opentelemetry.sdk.metrics.PeriodicExportingMetricReader()
            end
            
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["Resource"];
            resourcekeys = string.empty();
            resourcevalues = {};
            resource = dictionary(resourcekeys, resourcevalues);
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Resource")
                    if ~isa(valuei, "dictionary")
                        error("opentelemetry:sdk:metrics:MeterProvider:InvalidResourceType", ...
                            "Attibutes input must be a dictionary.");
                    end
                    resource = valuei;
                    resourcekeys = keys(valuei);
                    resourcevalues = values(valuei,"cell");
                    % collapse one level of cells, as this may be due to
                    % a behavior of dictionary.values
                    if all(cellfun(@iscell, resourcevalues))
                        resourcevalues = [resourcevalues{:}];
                    end
                end
            end

            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.MeterProviderProxy", ...
                "ConstructorArguments", {reader.Proxy.ID, resourcekeys, resourcevalues});
            obj.MetricReader = reader;
            obj.Resource = resource;
        end
        
        function addMetricReader(obj, reader)
        arguments
     	    obj
            reader (1,1) {mustBeA(reader, "opentelemetry.sdk.metrics.PeriodicExportingMetricReader")}
        end
            obj.Proxy.addMetricReader(reader.Proxy.ID);
            obj.MetricReader = [obj.MetricReader, reader];
        end
        
        function success = shutdown(obj)
            if ~obj.isShutdown
                success = obj.Proxy.shutdown();
                obj.isShutdown = success;
            else
                success = true;
            end
        end

    end
end
