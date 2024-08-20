// Copyright 2023-2024 The MathWorks, Inc.

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

    ViewProxy()
       : FilterAttributes(false) {
        REGISTER_METHOD(ViewProxy, setName);
        REGISTER_METHOD(ViewProxy, setDescription);
        REGISTER_METHOD(ViewProxy, setInstrumentName);
        REGISTER_METHOD(ViewProxy, setInstrumentType);
        REGISTER_METHOD(ViewProxy, setInstrumentUnit);
        REGISTER_METHOD(ViewProxy, setMeterName);
        REGISTER_METHOD(ViewProxy, setMeterVersion);
        REGISTER_METHOD(ViewProxy, setMeterSchema);
        REGISTER_METHOD(ViewProxy, setAllowedAttributes);
        REGISTER_METHOD(ViewProxy, setAggregation);
        REGISTER_METHOD(ViewProxy, setHistogramBinEdges);
    }
    
    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    void setName(libmexclass::proxy::method::Context& context);

    void setDescription(libmexclass::proxy::method::Context& context);

    void setInstrumentName(libmexclass::proxy::method::Context& context);

    void setInstrumentType(libmexclass::proxy::method::Context& context);

    void setInstrumentUnit(libmexclass::proxy::method::Context& context);

    void setMeterName(libmexclass::proxy::method::Context& context);

    void setMeterVersion(libmexclass::proxy::method::Context& context);

    void setMeterSchema(libmexclass::proxy::method::Context& context);

    void setAllowedAttributes(libmexclass::proxy::method::Context& context);

    void setAggregation(libmexclass::proxy::method::Context& context);

    void setHistogramBinEdges(libmexclass::proxy::method::Context& context);

    std::unique_ptr<metrics_sdk::View> getView();

    std::unique_ptr<metrics_sdk::InstrumentSelector> getInstrumentSelector();

    std::unique_ptr<metrics_sdk::MeterSelector> getMeterSelector();

private:
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
