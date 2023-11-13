classdef MeterProvider < handle
    % A meter provider stores a set of configurations used in a distributed
    % metrics system.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access={?opentelemetry.sdk.metrics.MeterProvider, ?opentelemetry.sdk.common.Cleanup})
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access={?opentelemetry.metrics.Provider, ?opentelemetry.sdk.metrics.MeterProvider})
        function obj = MeterProvider(skip)
            % constructor
            % "skip" input signals skipping construction
            if nargin < 1 || skip ~= "skip"
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.MeterProviderProxy", ...
                    "ConstructorArguments", {});
            end
        end
    end

    methods
        function meter = getMeter(obj, mname, mversion, mschema)
            % GETMETER Create a meter object used to generate metrics.
            %    M = GETMETER(MP, NAME) returns a meter with the name
            %    NAME that uses all the configurations specified in meter
            %    provider MP.
            %
            %    M = GETMETER(MP, NAME, VERSION, SCHEMA) also specifies
            %    the meter version and the URL that documents the schema
            %    of the generated meters.
            %
            %    See also OPENTELEMETRY.METRICS.METER
            arguments
                obj
                mname
                mversion = ""
                mschema = ""
            end
            % name, version, schema accepts any types that can convert to a
            % string
            import opentelemetry.common.mustBeScalarString
            mname = mustBeScalarString(mname);          
            mversion = mustBeScalarString(mversion);
            mschema = mustBeScalarString(mschema);
            id = obj.Proxy.getMeter(mname, mversion, mschema);
            meterproxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.MeterProxy", "ID", id);
            meter = opentelemetry.metrics.Meter(meterproxy, mname, mversion, mschema);
        end
        
        function setMeterProvider(obj)
            % SETMETERPROVIDER Set global instance of meter provider
            %    SETMETERPROVIDER(MP) sets the meter provider MP as
            %    the global instance.
            %
            %    See also OPENTELEMETRY.METRICS.PROVIDER.GETMETERPROVIDER
            obj.Proxy.setMeterProvider();
        end
    end

    methods(Access=?opentelemetry.sdk.common.Cleanup)
        function postShutdown(obj)
            % POSTSHUTDOWN  Handle post-shutdown tasks
            obj.Proxy.postShutdown();
        end
    end
end
