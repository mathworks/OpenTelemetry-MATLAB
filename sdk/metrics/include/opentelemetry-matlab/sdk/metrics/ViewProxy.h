// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/metrics/view/view.h"
#include "opentelemetry/sdk/metrics/view/view_factory.h"
#include "opentelemetry/sdk/metrics/instruments.h"
#include "opentelemetry/sdk/metrics/aggregation/aggregation.h"
#include "opentelemetry/sdk/metrics/aggregation/aggregation_config.h"
#include "opentelemetry/sdk/metrics/view/attributes_processor.h"
#include "opentelemetry/sdk/metrics/view/instrument_selector.h"
#include "opentelemetry/sdk/metrics/view/instrument_selector_factory.h"
#include "opentelemetry/nostd/string_view.h"
#include "opentelemetry/sdk/metrics/view/meter_selector.h"
#include "opentelemetry/sdk/metrics/view/meter_selector_factory.h"


#include "opentelemetry-matlab/sdk/metrics/ViewProxy.h"

namespace metrics_sdk = opentelemetry::sdk::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry::sdk {
class ViewProxy : public libmexclass::proxy::Proxy {
public:
    ViewProxy(std::string name, std::string description, std::string instrumentName, 
		metrics_sdk::InstrumentType instrumentType, std::string instrumentUnit, std::string meterName, 
		std::string meterVersion, std::string meterSchema, std::unordered_map<std::string, bool> allowedAttributes,
		bool filterAttributes, metrics_sdk::AggregationType aggregationType, std::vector<double> histogramBinEdges) 
       : Name(std::move(name)), Description(std::move(description)), InstrumentName(std::move(instrumentName)), InstrumentType(instrumentType), 
	InstrumentUnit(std::move(instrumentUnit)), MeterName(std::move(meterName)), MeterVersion(std::move(meterVersion)), MeterSchema(std::move(meterSchema)), 
	AllowedAttributes(std::move(allowedAttributes)), FilterAttributes(filterAttributes), Aggregation(aggregationType), HistogramBinEdges(std::move(histogramBinEdges)) {}

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metrics_sdk::View> getView();

    std::unique_ptr<metrics_sdk::InstrumentSelector> getInstrumentSelector();

    std::unique_ptr<metrics_sdk::MeterSelector> getMeterSelector();

private:
    std::unique_ptr<metrics_sdk::View> View;

    std::unique_ptr<metrics_sdk::InstrumentSelector> InstrumentSelector;
    
    std::string InstrumentName;
    metrics_sdk::InstrumentType InstrumentType;
    std::string InstrumentUnit;

    std::string MeterName;
    std::string MeterVersion;
    std::string MeterSchema;

    std::string Name;
    std::string Description;
    metrics_sdk::AggregationType Aggregation;
    std::vector<double> HistogramBinEdges;
    std::unordered_map<std::string, bool> AllowedAttributes;
    bool FilterAttributes;
};
}
