// Copyright 2023-2024 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/ViewProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult ViewProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    libmexclass::proxy::MakeResult out;

    // Name
    matlab::data::StringArray name_mda = constructor_arguments[0];
    std::string name = static_cast<std::string>(name_mda[0]);

    // Description
    matlab::data::StringArray description_mda = constructor_arguments[1];
    std::string description = static_cast<std::string>(description_mda[0]);
    
    // InstrumentName
    matlab::data::StringArray instrument_name_mda = constructor_arguments[2];
    auto instrument_name = static_cast<std::string>(instrument_name_mda[0]);

    // InstrumentType
    matlab::data::StringArray instrument_type_mda = constructor_arguments[3];
    matlab::data::String instrument_type_str = instrument_type_mda[0];
    metrics_sdk::InstrumentType instrument_type;
    if (instrument_type_str.compare(u"counter") == 0) {
        instrument_type = metrics_sdk::InstrumentType::kCounter;
    } else if (instrument_type_str.compare(u"updowncounter") == 0) {
	instrument_type = metrics_sdk::InstrumentType::kUpDownCounter;
    } else if (instrument_type_str.compare(u"histogram") == 0) {
	instrument_type = metrics_sdk::InstrumentType::kHistogram;
    } else if (instrument_type_str.compare(u"observablecounter") == 0) {
	instrument_type = metrics_sdk::InstrumentType::kObservableCounter;
    } else if (instrument_type_str.compare(u"observableupdowncounter") == 0) {
	instrument_type = metrics_sdk::InstrumentType::kObservableUpDownCounter;
    } else {
	assert(instrument_type_str.compare(u"observablegauge") == 0);
	instrument_type = metrics_sdk::InstrumentType::kObservableGauge;
    }

    // InstrumentUnit
    matlab::data::StringArray unit_mda = constructor_arguments[4];
    auto instrument_unit = static_cast<std::string>(unit_mda[0]);


    // MeterName
    matlab::data::StringArray meter_name_mda = constructor_arguments[5];
    auto meter_name = static_cast<std::string>(meter_name_mda[0]);

    // MeterVersion
    matlab::data::StringArray meter_version_mda = constructor_arguments[6];
    auto meter_version = static_cast<std::string>(meter_version_mda[0]);

    // MeterSchema
    matlab::data::StringArray meter_schema_mda = constructor_arguments[7];
    auto meter_schema = static_cast<std::string>(meter_schema_mda[0]);

    // FilterAttributes (a boolean indicating whether AllowedAttributes has been specified)
    matlab::data::TypedArray<bool> filter_attributes_mda = constructor_arguments[8];
    bool filter_attributes = filter_attributes_mda[0];

    // AllowedAttributes
    std::unique_ptr<metrics_sdk::AttributesProcessor> attributes_processor;
    matlab::data::StringArray attributes_mda = constructor_arguments[9];
    std::unordered_map<std::string, bool> allowed_attribute_keys;
    for (size_t a=0; a<attributes_mda.getNumberOfElements(); a++) {
	std::string attr = static_cast<std::string>(attributes_mda[a]);
	if (!attr.empty()) {
            allowed_attribute_keys[attr] = true;
	}
    }

    // Aggregation
    matlab::data::StringArray aggregation_type_mda = constructor_arguments[10];
    matlab::data::String aggregation_type_str = aggregation_type_mda[0];
    metrics_sdk::AggregationType aggregation_type;
    if (aggregation_type_str.compare(u"sum") == 0) {
        aggregation_type = metrics_sdk::AggregationType::kSum;
    } else if (aggregation_type_str.compare(u"drop") == 0) {
        aggregation_type = metrics_sdk::AggregationType::kDrop;
    } else if (aggregation_type_str.compare(u"lastvalue") == 0) {
        aggregation_type = metrics_sdk::AggregationType::kLastValue;
    } else if (aggregation_type_str.compare(u"histogram") == 0) {
        aggregation_type = metrics_sdk::AggregationType::kHistogram;
    } else {
        assert(aggregation_type_str.compare(u"default") == 0);
        aggregation_type = metrics_sdk::AggregationType::kDefault;
    }

    // HistogramBinEdges
    std::vector<double> histogramBinEdges;
    if(aggregation_type == metrics_sdk::AggregationType::kHistogram ||
		    (aggregation_type == metrics_sdk::AggregationType::kDefault && instrument_type == metrics_sdk::InstrumentType::kHistogram)){
        matlab::data::TypedArray<double> histogramBinEdges_mda = constructor_arguments[11];
        for (auto h : histogramBinEdges_mda) {
            histogramBinEdges.push_back(h);
        }
    }
    
    // Call View Proxy Constructor
    return std::make_shared<ViewProxy>(std::move(name), std::move(description), std::move(instrument_name), instrument_type, 
		    std::move(instrument_unit), std::move(meter_name), std::move(meter_version), std::move(meter_schema), 
		    std::move(allowed_attribute_keys), filter_attributes, aggregation_type, std::move(histogramBinEdges));
}

std::unique_ptr<metrics_sdk::View> ViewProxy::getView(){
    // AttributesProcessor
    std::unique_ptr<metrics_sdk::AttributesProcessor> attributes_processor;
    if(FilterAttributes){
        attributes_processor = std::unique_ptr<metrics_sdk::AttributesProcessor>(new metrics_sdk::FilteringAttributesProcessor(AllowedAttributes));
    }else{
        attributes_processor = std::unique_ptr<metrics_sdk::AttributesProcessor>(new metrics_sdk::DefaultAttributesProcessor());
    }
    
    // HistogramAggregationConfig
    auto aggregation_config = std::shared_ptr<metrics_sdk::HistogramAggregationConfig>(new metrics_sdk::HistogramAggregationConfig());
    if(Aggregation == metrics_sdk::AggregationType::kHistogram ||
		    (Aggregation == metrics_sdk::AggregationType::kDefault && InstrumentType == metrics_sdk::InstrumentType::kHistogram)){
        aggregation_config->boundaries_ = HistogramBinEdges;
    }

    // View
    return metrics_sdk::ViewFactory::Create(Name, Description, "", Aggregation, aggregation_config, std::move(attributes_processor));
}

std::unique_ptr<metrics_sdk::InstrumentSelector> ViewProxy::getInstrumentSelector(){
    return metrics_sdk::InstrumentSelectorFactory::Create(InstrumentType, InstrumentName, InstrumentUnit);
}

std::unique_ptr<metrics_sdk::MeterSelector> ViewProxy::getMeterSelector(){
    return metrics_sdk::MeterSelectorFactory::Create(MeterName, MeterVersion, MeterSchema);
}

}
