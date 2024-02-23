classdef View
    % View enables customization of output metrics. Supported customization
    % includes:
    %   * Metric name
    %   * Aggregation type
    %   * Histogram bins
    %   * Ignore unwanted instruments
    %   * Ignore unwanted attributes

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.metrics.MeterProvider})
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=immutable)
        Name                (1,1) string    % View name
        Description         (1,1) string    % Description of view
        InstrumentName      (1,1) string    % Name of the instrument this view applies to
        InstrumentType      (1,1) string    % Type of instrument this view applies to
        InstrumentUnit      (1,1) string    % Unit of instrument this view applies to
        MeterName           (1,1) string    % Name of the meter this view applies to
        MeterVersion        (1,1) string    % Version of the meter this view applies to
        MeterSchema         (1,1) string    % Schema URL of the meter this view applies to
        AllowedAttributes   (1,:) string    % List of attribute keys that are kept. All other attributes are ignored.
        Aggregation         (1,1) string    % Customized aggregation type
        HistogramBinEdges   (1,:) double    % Vector of customized bin edges for histogram  
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
                options.Name {mustBeTextScalar} = ""
                options.Description {mustBeTextScalar} = ""
                options.InstrumentName {mustBeTextScalar} = "*"
                options.InstrumentType {mustBeTextScalar} = "counter"
                options.InstrumentUnit {mustBeTextScalar} = ""
                options.MeterName {mustBeTextScalar} = ""
                options.MeterVersion {mustBeTextScalar} = ""
                options.MeterSchema {mustBeTextScalar} = ""
                options.AllowedAttributes {mustBeText, mustBeVector}   % no default here
                options.Aggregation {mustBeTextScalar} = "default"
                options.HistogramBinEdges {mustBeNumeric, mustBeVector} = zeros(1,0)
            end

            instrument_types = ["counter", "histogram", "updowncounter", ...
                "observablecounter", "observableupdowncounter", "observablegauge"];
            instrument_type = validatestring(options.InstrumentType, instrument_types);

            aggregation_types = ["drop", "histogram", "lastvalue", "sum", "default"];
            aggregation_type = validatestring(options.Aggregation, aggregation_types);
            
            % check whether AllowedAttributes is defined
            filter_attributes = isfield(options, "AllowedAttributes");
            if ~filter_attributes
                % put some defaults here, which will be ignored since filter_attributes is false
                options.AllowedAttributes = strings(1,0);  
            end

            obj.Proxy = libmexclass.proxy.Proxy("Name", "libmexclass.opentelemetry.sdk.ViewProxy", ...
                "ConstructorArguments", {options.Name, options.Description, options.InstrumentName, ...
                instrument_type, options.InstrumentUnit, options.MeterName, ...
                options.MeterVersion, options.MeterSchema, filter_attributes,...
                options.AllowedAttributes, aggregation_type, options.HistogramBinEdges});

            obj.Name = string(options.Name);
            obj.Description = string(options.Description);            
            obj.InstrumentName = string(options.InstrumentName);
            obj.InstrumentType = instrument_type;
            obj.InstrumentUnit = string(options.InstrumentUnit);
            obj.MeterName = string(options.MeterName);
            obj.MeterVersion = string(options.MeterVersion);
            obj.MeterSchema = string(options.MeterSchema);
            obj.AllowedAttributes = reshape(string(options.AllowedAttributes),1,[]);
            obj.Aggregation = aggregation_type;
            obj.HistogramBinEdges = reshape(double(options.HistogramBinEdges),1,[]);
        end
    end
end