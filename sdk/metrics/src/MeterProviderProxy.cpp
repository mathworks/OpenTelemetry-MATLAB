// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/metrics/meter_provider_factory.h"

namespace metrics_sdk = opentelemetry::sdk::metrics;

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult MeterProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    libmexclass::proxy::MakeResult out;
    out = std::make_shared<MeterProviderProxy>(nostd::shared_ptr<metrics_api::MeterProvider>(
	    std::move(metrics_sdk::MeterProviderFactory::Create())));
    return out;
}

} // namespace libmexclass::opentelemetry
