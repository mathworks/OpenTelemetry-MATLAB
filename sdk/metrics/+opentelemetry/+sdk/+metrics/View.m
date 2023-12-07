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
                options.name=""
                options.description=""
                options.unit=""
                options.instrumentName=""
                options.instrumentType=""
                options.meterName=""
                options.meterVersion=""
                options.meterSchemaURL=""
                options.attributeKeys=""
                options.aggregation=""
                options.histogramBinEdges=[]
            end
            
            instrumentTypeCategory = int32(find(options.instrumentType==["kCounter", "kHistogram", "kUpDownCounter", "kObservableCounter", "kObservableGauge", "kObservableUpDownCounter"])-1);

            aggregationCategory = int32(find(options.aggregation==["kDrop", "kHistogram", "kLastValue", "kSum", "kDefault"])-1);

            if(numel(instrumentTypeCategory)==0)
                instrumentTypeCategory = int32(-1);
            end
            if(numel(aggregationCategory)==0)
                aggregationCategory = int32(-1);
            end
            
            obj.Proxy = libmexclass.proxy.Proxy("Name", "libmexclass.opentelemetry.sdk.ViewProxy", ...
                "ConstructorArguments", {options.name, options.description, options.unit, options.instrumentName, ...
                instrumentTypeCategory, options.meterName, options.meterVersion, options.meterSchemaURL, ...
                options.attributeKeys, aggregationCategory, options.histogramBinEdges});

            obj.Name = options.name;
            obj.Description = options.description;
            obj.Unit = options.unit;
            obj.InstrumentName = options.instrumentName;
            obj.InstrumentType = options.instrumentType;
            obj.MeterName = options.meterName;
            obj.MeterVersion = options.meterVersion;
            obj.MeterSchemaURL = options.meterSchemaURL;
            obj.AttributeKeys = options.attributeKeys;
            obj.Aggregation = options.aggregation;
            obj.HistogramBinEdges = options.histogramBinEdges;
        end
    end
end