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
    ViewProxy(std::unique_ptr<metrics_sdk::View> view, std::unique_ptr<metrics_sdk::InstrumentSelector> instrumentSelector, std::unique_ptr<metrics_sdk::MeterSelector> meterSelector);

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    // void processView(libmexclass::proxy::method::Context& context);

    std::unique_ptr<metrics_sdk::View> getView(libmexclass::proxy::method::Context& context);

    std::unique_ptr<metrics_sdk::InstrumentSelector> getInstrumentSelector(libmexclass::proxy::method::Context& context);

    std::unique_ptr<metrics_sdk::MeterSelector> getMeterSelector(libmexclass::proxy::method::Context& context);

private:
    std::unique_ptr<metrics_sdk::View> View;

    std::unique_ptr<metrics_sdk::InstrumentSelector> InstrumentSelector;
    
    std::unique_ptr<metrics_sdk::MeterSelector> MeterSelector;
};
}
