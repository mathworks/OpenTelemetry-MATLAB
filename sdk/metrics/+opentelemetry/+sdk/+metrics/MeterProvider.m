classdef MeterProvider < opentelemetry.metrics.MeterProvider & handle
    % An SDK implementation of meter provider, which stores a set of configurations used
    % in a metrics system.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access=public)
        MetricReader
    end

    methods
        function obj = MeterProvider(reader)
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
            
            % explicit call to superclass constructor to make it a no-op
            obj@opentelemetry.metrics.MeterProvider("skip");

            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.MeterProviderProxy", ...
                "ConstructorArguments", {reader.Proxy.ID});
            obj.MetricReader = reader;
        end
        
        function addMetricReader(obj, reader)
        arguments
     	    obj
            reader (1,1) {mustBeA(reader, "opentelemetry.sdk.metrics.PeriodicExportingMetricReader")}
        end
            obj.Proxy.addMetricReader(reader.Proxy.ID);
            obj.MetricReader = [obj.MetricReader, reader];
        end

    end
end
