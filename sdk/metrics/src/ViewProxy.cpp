// Copyright 2023-2026 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/ViewProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult ViewProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    return std::make_shared<ViewProxy>();
}

// Setters for properties
void ViewProxy::setName(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray name_mda = context.inputs[0];
    Name = static_cast<std::string>(name_mda[0]);
}

void ViewProxy::setDescription(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray description_mda = context.inputs[0];
    Description = static_cast<std::string>(description_mda[0]);
}

void ViewProxy::setInstrumentName(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray instrumentname_mda = context.inputs[0];
    InstrumentName = static_cast<std::string>(instrumentname_mda[0]);
}

void ViewProxy::setInstrumentType(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray instrumenttype_mda = context.inputs[0];
    matlab::data::String instrument_type_str = instrumenttype_mda[0];
    if (instrument_type_str.compare(u"counter") == 0) {
        InstrumentType = metrics_sdk::InstrumentType::kCounter;
    } else if (instrument_type_str.compare(u"updowncounter") == 0) {
	InstrumentType = metrics_sdk::InstrumentType::kUpDownCounter;
    } else if (instrument_type_str.compare(u"histogram") == 0) {
	InstrumentType = metrics_sdk::InstrumentType::kHistogram;
    } else if (instrument_type_str.compare(u"gauge") == 0) {
	InstrumentType = metrics_sdk::InstrumentType::kGauge;
    } else if (instrument_type_str.compare(u"observablecounter") == 0) {
	InstrumentType = metrics_sdk::InstrumentType::kObservableCounter;
    } else if (instrument_type_str.compare(u"observableupdowncounter") == 0) {
	InstrumentType = metrics_sdk::InstrumentType::kObservableUpDownCounter;
    } else {
	assert(instrument_type_str.compare(u"observablegauge") == 0);
	InstrumentType = metrics_sdk::InstrumentType::kObservableGauge;
    }
}

void ViewProxy::setInstrumentUnit(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray instrumentunit_mda = context.inputs[0];
    InstrumentUnit = static_cast<std::string>(instrumentunit_mda[0]);
}

void ViewProxy::setMeterName(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray metername_mda = context.inputs[0];
    MeterName = static_cast<std::string>(metername_mda[0]);
}

void ViewProxy::setMeterVersion(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray meterversion_mda = context.inputs[0];
    MeterVersion = static_cast<std::string>(meterversion_mda[0]);
}

void ViewProxy::setMeterSchema(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray meterschema_mda = context.inputs[0];
    MeterSchema = static_cast<std::string>(meterschema_mda[0]);
}

void ViewProxy::setAllowedAttributes(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray attributes_mda = context.inputs[0];
    if (attributes_mda.getNumberOfElements() == 1 && static_cast<matlab::data::String>(attributes_mda[0]).compare(u"*") == 0) {
	FilterAttributes = false;
    } else {
        FilterAttributes = true;
	AllowedAttributes.clear();    // clear all previous entries
        for (size_t a=0; a<attributes_mda.getNumberOfElements(); a++) {
	    std::string attr = static_cast<std::string>(attributes_mda[a]);
	    if (!attr.empty()) {
                AllowedAttributes[attr] = true;
	    }
        }
    }
}

void ViewProxy::setAggregation(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray aggregation_type_mda = context.inputs[0];
    matlab::data::String aggregation_type_str = aggregation_type_mda[0];
    if (aggregation_type_str.compare(u"sum") == 0) {
        Aggregation = metrics_sdk::AggregationType::kSum;
    } else if (aggregation_type_str.compare(u"drop") == 0) {
        Aggregation = metrics_sdk::AggregationType::kDrop;
    } else if (aggregation_type_str.compare(u"lastvalue") == 0) {
        Aggregation = metrics_sdk::AggregationType::kLastValue;
    } else if (aggregation_type_str.compare(u"histogram") == 0) {
        Aggregation = metrics_sdk::AggregationType::kHistogram;
    } else {
        assert(aggregation_type_str.compare(u"default") == 0);
        Aggregation = metrics_sdk::AggregationType::kDefault;
    }
}

void ViewProxy::setHistogramBinEdges(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> histogramBinEdges_mda = context.inputs[0];
    for (auto h : histogramBinEdges_mda) {
        HistogramBinEdges.push_back(h);
    }
}
    
// Methods to generate input objects for MeterProvider.addView
std::unique_ptr<metrics_sdk::View> ViewProxy::getView(){
    // AttributesProcessor
    std::unique_ptr<metrics_sdk::AttributesProcessor> attributes_processor;
    if(FilterAttributes){
        attributes_processor = std::unique_ptr<metrics_sdk::AttributesProcessor>(new metrics_sdk::FilteringAttributesProcessor(AllowedAttributes));
    }else{
        attributes_processor = std::unique_ptr<metrics_sdk::AttributesProcessor>(new metrics_sdk::DefaultAttributesProcessor());
    }
    
    // HistogramAggregationConfig
    std::shared_ptr<metrics_sdk::AggregationConfig> aggregation_config;
    if(Aggregation == metrics_sdk::AggregationType::kHistogram ||
		    (Aggregation == metrics_sdk::AggregationType::kDefault && InstrumentType == metrics_sdk::InstrumentType::kHistogram)){
	auto histogram_aggregation_config = std::make_shared<metrics_sdk::HistogramAggregationConfig>();
        histogram_aggregation_config->boundaries_ = HistogramBinEdges;
	aggregation_config = histogram_aggregation_config;
    } else {
	aggregation_config = std::make_shared<metrics_sdk::AggregationConfig>();
    }

    // View
    return metrics_sdk::ViewFactory::Create(Name, Description, Aggregation, aggregation_config, std::move(attributes_processor));
}

std::unique_ptr<metrics_sdk::InstrumentSelector> ViewProxy::getInstrumentSelector(){
    return metrics_sdk::InstrumentSelectorFactory::Create(InstrumentType, InstrumentName, InstrumentUnit);
}

std::unique_ptr<metrics_sdk::MeterSelector> ViewProxy::getMeterSelector(){
    return metrics_sdk::MeterSelectorFactory::Create(MeterName, MeterVersion, MeterSchema);
}

}
