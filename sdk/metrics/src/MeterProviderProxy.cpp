// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"
#include "opentelemetry-matlab/sdk/metrics/PeriodicExportingMetricReaderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include <chrono>

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult MeterProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    
    libmexclass::proxy::MakeResult out;

    matlab::data::TypedArray<uint64_t> readerid_mda = constructor_arguments[0];
    libmexclass::proxy::ID readerid = readerid_mda[0];
    
    matlab::data::StringArray resourcenames_mda = constructor_arguments[1];
    size_t nresourceattrs = resourcenames_mda.getNumberOfElements();
    matlab::data::CellArray resourcevalues_mda = constructor_arguments[2];

    auto resource_custom = createResource(resourcenames_mda, resourcevalues_mda);

    auto reader = std::static_pointer_cast<PeriodicExportingMetricReaderProxy>(
	        libmexclass::proxy::ProxyManager::getProxy(readerid))->getInstance();
    auto p = metrics_sdk::MeterProviderFactory::Create(NULL, std::move(resource_custom));
    auto *p_sdk = static_cast<metrics_sdk::MeterProvider *>(p.get());
    p_sdk->AddMetricReader(std::move(reader));
    
    auto p_out = nostd::shared_ptr<metrics_api::MeterProvider>(std::move(p));

    out = std::make_shared<MeterProviderProxy>(p_out);

    return out;
}

void MeterProviderProxy::addMetricReader(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> readerid_mda = context.inputs[0];
    libmexclass::proxy::ID readerid = readerid_mda[0];

    static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).AddMetricReader(
		    std::static_pointer_cast<PeriodicExportingMetricReaderProxy>(
			    libmexclass::proxy::ProxyManager::getProxy(readerid))->getInstance());
   return;
}


} // namespace libmexclass::opentelemetry
