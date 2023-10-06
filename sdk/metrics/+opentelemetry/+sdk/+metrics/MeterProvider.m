classdef MeterProvider < opentelemetry.metrics.MeterProvider & handle
    % An SDK implementation of meter provider, which stores a set of configurations used
    % in a metrics system.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access=private)
	    isShutdown (1,1) logical = false
    end

    methods
        function obj = MeterProvider()
            % SDK implementation of meter provider
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
            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.MeterProviderProxy", ...
                "ConstructorArguments", {});
        end
        
    end
end
