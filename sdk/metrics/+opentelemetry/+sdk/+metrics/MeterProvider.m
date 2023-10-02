classdef MeterProvider < handle
    % An SDK implementation of meter provider, which stores a set of configurations used
    % in a metrics system.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
	    Proxy
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

            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.MeterProviderProxy", ...
                "ConstructorArguments", {reader.Proxy.ID});
        end

        function meter = getMeter(obj, mtname, mtversion, mtschema)
            arguments
                obj
                mtname
                mtversion = ""
                mtschema = ""
            end
            % name, version, schema accepts any types that can convert to a
            % string
            import opentelemetry.common.mustBeScalarString
            mtname = mustBeScalarString(mtname);          
            mtversion = mustBeScalarString(mtversion);
            mtschema = mustBeScalarString(mtschema);
            id = obj.Proxy.getMeter(mtname, mtversion, mtschema);
            Meterproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.MeterProxy", "ID", id);
            meter = opentelemetry.metrics.Meter(Meterproxy, mtname, mtversion, mtschema);
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
