classdef View

% Copyright 2023 The MathWorks, Inc.

    properties (GetAccess={?opentelemetry.sdk.metrics.MeterProvider})
        Proxy  % Proxy object to interface C++ code
    end

    properties (SetAccess=immutable)
        Name
        Description
        Unit
        InstrumentName
        InstrumentType
        MeterName
        MeterVersion
        MeterSchemaURL
        AttributeKeys
        Aggregation
        HistogramBinEdges
    end

    methods
        function obj = View(options)
            arguments
                options.Name=""
                options.Description=""
                options.Unit=""
                options.InstrumentName=""
                options.InstrumentType=""
                options.MeterName=""
                options.MeterVersion=""
                options.MeterSchemaURL=""
                options.AttributeKeys=""
                options.Aggregation=""
                options.HistogramBinEdges=[]
            end
            
            instrument_types = ["Counter", "Histogram", "UpDownCounter", "ObservableCounter", "ObservableGauge", "ObservableUpDownCounter"];
            instrument_type = validatestring(options.InstrumentType, instrument_types);
            instrumentTypeCategory = find(instrument_type==instrument_types)-1;

            aggregation_types = ["Drop", "Histogram", "LastValue", "Sum", "Default"];
            aggregation_type = validatestring(options.Aggregation, aggregation_types);
            aggregationCategory = find(aggregation_type==aggregation_types)-1;
            
            obj.Proxy = libmexclass.proxy.Proxy("Name", "libmexclass.opentelemetry.sdk.ViewProxy", ...
                "ConstructorArguments", {options.Name, options.Description, options.Unit, options.InstrumentName, ...
                instrumentTypeCategory, options.MeterName, options.MeterVersion, options.MeterSchemaURL, ...
                options.AttributeKeys, aggregationCategory, options.HistogramBinEdges});

            obj.Name = options.Name;
            obj.Description = options.Description;
            obj.Unit = options.Unit;
            obj.InstrumentName = options.InstrumentName;
            obj.InstrumentType = options.InstrumentType;
            obj.MeterName = options.MeterName;
            obj.MeterVersion = options.MeterVersion;
            obj.MeterSchemaURL = options.MeterSchemaURL;
            obj.AttributeKeys = options.AttributeKeys;
            obj.Aggregation = options.Aggregation;
            obj.HistogramBinEdges = options.HistogramBinEdges;
        end
    end
end