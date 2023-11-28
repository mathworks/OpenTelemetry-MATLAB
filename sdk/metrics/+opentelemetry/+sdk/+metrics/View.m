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
        function obj = View(name, description, unit, instrumentName, instrumentType, ...
                meterName, meterVersion, meterSchemaURL, attributeKeys, ...
                aggregation, histogramBinEdges, varargin)

            instrumentTypeCategory = int32(find(instrumentType==["kCounter", "kHistogram", "kUpDownCounter", "kObservableCounter", "kObservableGauge", "kObservableUpDownCounter"])-1);

            aggregationCategory = int32(find(aggregation==["kDrop", "kHistogram", "kLastValue", "kSum", "kDefault"])-1);

            obj.Proxy = libmexclass.proxy.Proxy("Name", "libmexclass.opentelemetry.sdk.ViewProxy", ...
                "ConstructorArguments", {name, description, unit, instrumentName, ...
                instrumentTypeCategory, meterName, meterVersion, meterSchemaURL, ...
                attributeKeys, aggregationCategory, histogramBinEdges, varargin});
            obj.Description = description;
            obj.Unit = unit;
            obj.InstrumentName = instrumentName;
            obj.InstrumentType = instrumentType;
            obj.MeterName = meterName;
            obj.MeterVersion = meterVersion;
            obj.MeterSchemaURL = meterSchemaURL;
            obj.AttributeKeys = attributeKeys;
            obj.Aggregation = aggregation;
            obj.HistogramBinEdges = histogramBinEdges;
        end
    end
end