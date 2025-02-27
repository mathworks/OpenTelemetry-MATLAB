classdef View
    % View enables customization of output metrics. Supported customization
    % includes:
    %   * Metric name
    %   * Aggregation type
    %   * Histogram bins
    %   * Ignore unwanted instruments
    %   * Ignore unwanted attributes

    % Copyright 2023-2025 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.metrics.MeterProvider})
        Proxy  % Proxy object to interface C++ code
    end

    properties 
        Name                (1,1) string = ""            % View name
        Description         (1,1) string = ""            % Description of view
        InstrumentName      (1,1) string                 % Name of the instrument this view applies to
        InstrumentType      (1,1) string                 % Type of instrument this view applies to
        InstrumentUnit      (1,1) string = ""            % Unit of instrument this view applies to
        MeterName           (1,1) string = ""            % Name of the meter this view applies to
        MeterVersion        (1,1) string = ""            % Version of the meter this view applies to
        MeterSchema         (1,1) string = ""            % Schema URL of the meter this view applies to
        AllowedAttributes   (1,:) string                 % List of attribute keys that are kept. All other attributes are ignored.
        Aggregation         (1,1) string                 % Customized aggregation type
        HistogramBinEdges   (1,:) double = zeros(1,0)    % Vector of customized bin edges for histogram  
    end

    methods
        function obj = View(options)
            % View enables customization of output metrics
            %    V = OPENTELEMETRY.SDK.METRICS.VIEW(PARAM1, VALUE1, PARAM2,
            %    VALUE2, ...) creates a view object and specifies its
            %    behavior using parameter name/value pairs. Parameters are:
            %       "Name"            - Name of view. Any metric this view
            %                           applies to will be renamed to this name.
            %       "Description"     - Description of view.
            %       "InstrumentName"  - Specifies an instrument name. This
            %                           view will be applied to all metrics
            %                           generated from instruments with
            %                           this name.
            %       "InstrumentType"  - Specifies an instrument type. This
            %                           view will be applied to all metrics
            %                           generated from all instruments of
            %                           this type.
            %       "InstrumentUnit"  - Specifies an instrument unit. This
            %                           view will be applied to all metrics
            %                           generated from all instruments with
            %                           this unit.
            %       "MeterName"       - Specifies a meter name. This view
            %                           will be applied to all metrics
            %                           generated from all instruments created
            %                           by meters with this name.
            %       "MeterVersion"    - Specifies a meter version. This view
            %                           will be applied to all metrics
            %                           generated from all instruments created
            %                           by meters with this version.
            %       "MeterSchema"     - Specifies a meter schema URL. This view
            %                           will be applied to all metrics
            %                           generated from all instruments created
            %                           by meters with this schema URL.
            %       "AllowedAttributes"   - Specifies a list of attributes
            %                               that will be kept. All other
            %                               attributes will be dropped.
            %       "Aggregation"     - Change instruments to use a
            %                           different aggregation beahvior.
            %       "HistogramBinEdges"   - Use a different set of bins
            %                               in all histograms this view
            %                               applies to
            %
            %    Examples:
            %       import opentelemetry.sdk.metrics
            %
            %       % Change bin edges of all histograms created by any
            %       % meter named "Meter1"
            %       v = view(InstrumentType="histogram", MeterName="Meter1", ...
            %              HistogramBinEdges = 0:100:500);
            %
            %       % Ignore all counters created by any meter named "xyz"
            %       v = view(MeterName="xyz", InstrumentType="counter", ...
            %              Aggregation="drop");
            %
            %    See also OPENTELEMETRY.SDK.METRICS.METERPROVIDER
            arguments
                options.Name {mustBeTextScalar}
                options.Description {mustBeTextScalar}
                options.InstrumentName {mustBeTextScalar} = "*"
                options.InstrumentType {mustBeTextScalar} = "counter"
                options.InstrumentUnit {mustBeTextScalar}
                options.MeterName {mustBeTextScalar}
                options.MeterVersion {mustBeTextScalar}
                options.MeterSchema {mustBeTextScalar}
                options.AllowedAttributes {mustBeText, mustBeVector} = "*"  
                options.Aggregation {mustBeTextScalar} = "default"
                options.HistogramBinEdges {mustBeNumeric, mustBeVector} 
            end

            obj.Proxy = libmexclass.proxy.Proxy("Name", "libmexclass.opentelemetry.sdk.ViewProxy", ...
                "ConstructorArguments", {});

            if isfield(options, "Name")
                obj.Name = options.Name;
            end
            if isfield(options, "Description")
                obj.Description = options.Description;
            end
            obj.InstrumentName = options.InstrumentName;
            obj.InstrumentType = options.InstrumentType;
            if isfield(options, "InstrumentUnit")
                obj.InstrumentUnit = options.InstrumentUnit;
            end
            if isfield(options, "MeterName")
                obj.MeterName = options.MeterName;
            end
            if isfield(options, "MeterVersion")
                obj.MeterVersion = options.MeterVersion;
            end
            if isfield(options, "MeterSchema")
                obj.MeterSchema = options.MeterSchema;
            end
            obj.AllowedAttributes = options.AllowedAttributes;
            obj.Aggregation = options.Aggregation;
            if isfield(options, "HistogramBinEdges")
                obj.HistogramBinEdges = options.HistogramBinEdges;
            end
        end

        function obj = set.Name(obj, name)
            arguments
                obj
                name  {mustBeTextScalar}
            end
            name = string(name);
            obj.Proxy.setName(name); %#ok<*MCSUP>
            obj.Name = name;
        end

        function obj = set.Description(obj, desc)
            arguments
                obj
                desc  {mustBeTextScalar}
            end
            desc = string(desc);
            obj.Proxy.setDescription(desc);
            obj.Description = desc;
        end

        function obj = set.InstrumentName(obj, instname)
            arguments
                obj
                instname  {mustBeTextScalar}
            end
            instname = string(instname);
            obj.Proxy.setInstrumentName(instname);
            obj.InstrumentName = instname;
        end

        function obj = set.InstrumentType(obj, insttype)
            arguments
                obj
                insttype  {mustBeTextScalar}
            end
            instrument_types = ["counter", "histogram", "updowncounter", "gauge", ...
                "observablecounter", "observableupdowncounter", "observablegauge"];
            insttype = validatestring(insttype, instrument_types);
            obj.Proxy.setInstrumentType(insttype);
            obj.InstrumentType = insttype;
        end

        function obj = set.InstrumentUnit(obj, instunit)
            arguments
                obj
                instunit  {mustBeTextScalar}
            end
            instunit = string(instunit);
            obj.Proxy.setInstrumentUnit(instunit);
            obj.InstrumentUnit = instunit;
        end

        function obj = set.MeterName(obj, metername)
            arguments
                obj
                metername  {mustBeTextScalar}
            end
            metername = string(metername);
            obj.Proxy.setMeterName(metername)
            obj.MeterName = metername;
        end

        function obj = set.MeterVersion(obj, meterversion)
            arguments
                obj
                meterversion  {mustBeTextScalar}
            end
            meterversion = string(meterversion);
            obj.Proxy.setMeterVersion(meterversion);
            obj.MeterVersion = meterversion;
        end

        function obj = set.MeterSchema(obj, meterschema)
            arguments
                obj
                meterschema  {mustBeTextScalar}
            end
            meterschema = string(meterschema);
            obj.Proxy.setMeterSchema(meterschema);
            obj.MeterSchema = meterschema;
        end

        function obj = set.AllowedAttributes(obj, attrs)
            arguments
                obj
                attrs  {mustBeText, mustBeVector} 
            end
            attrs = reshape(string(attrs),1,[]);
            obj.Proxy.setAllowedAttributes(attrs);
            obj.AllowedAttributes = attrs;
        end

        function obj = set.Aggregation(obj, agg)
            arguments
                obj
                agg  {mustBeTextScalar}
            end            
            aggregation_types = ["drop", "histogram", "lastvalue", "sum", "default"];
            agg = validatestring(agg, aggregation_types);
            obj.Proxy.setAggregation(agg);
            obj.Aggregation = agg;
        end

        function obj = set.HistogramBinEdges(obj, binedges)
            arguments
                obj
                binedges  {mustBeNumeric, mustBeVector} 
            end
            binedges = reshape(double(binedges),1,[]);
            obj.Proxy.setHistogramBinEdges(binedges);
            obj.HistogramBinEdges = binedges;
        end
    end
end
