// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"
#include "opentelemetry-matlab/sdk/metrics/PeriodicExportingMetricReaderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include <chrono>

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult MeterProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    
    libmexclass::proxy::MakeResult out;
    matlab::data::TypedArray<bool> is_api = constructor_arguments[1];
    if (is_api[0])  {
        // if argument is 1, assume it is an API Meter Provider to support type conversion
        matlab::data::TypedArray<uint64_t> mpid_mda = constructor_arguments[0];
        libmexclass::proxy::ID mpid = mpid_mda[0];
        auto mp = std::static_pointer_cast<libmexclass::opentelemetry::MeterProviderProxy>(
            libmexclass::proxy::ProxyManager::getProxy(mpid))->getInstance();
        // check if input can be cast to an SDK Meter Provider 
        auto mpsdk = dynamic_cast<metrics_sdk::MeterProvider*>(mp.get());
        if (mpsdk == nullptr) {
          return libmexclass::error::Error{"opentelemetry:sdk:metrics:Cleanup:UnsetGlobalInstance", 
          "Clean up operations are not supported if global MeterProvider instance is not set."};
        }
        out = std::make_shared<MeterProviderProxy>(nostd::shared_ptr<metrics_api::MeterProvider>(mp));
    } else {
        matlab::data::TypedArray<uint64_t> readerid_mda = constructor_arguments[0];
        libmexclass::proxy::ID readerid = readerid_mda[0];
        
        auto reader = std::static_pointer_cast<PeriodicExportingMetricReaderProxy>(
	            libmexclass::proxy::ProxyManager::getProxy(readerid))->getInstance();
        auto p = metrics_sdk::MeterProviderFactory::Create();
        auto *p_sdk = static_cast<metrics_sdk::MeterProvider *>(p.get());
        p_sdk->AddMetricReader(std::move(reader));
      
        auto p_out = nostd::shared_ptr<metrics_api::MeterProvider>(std::move(p));
        out = std::make_shared<MeterProviderProxy>(p_out);
    }
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

void MeterProviderProxy::shutdown(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;
    auto result_mda = factory.createScalar(static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).Shutdown());
    context.outputs[0] = result_mda;
    nostd::shared_ptr<metrics_api::MeterProvider> noop(new metrics_api::NoopMeterProvider);
    CppMeterProvider.swap(noop);
}

void MeterProviderProxy::forceFlush(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;

    if (context.inputs.getNumberOfElements() == 0) {
        context.outputs[0] = factory.createScalar(static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).ForceFlush());
    } else {  // number of inputs > 0
        matlab::data::TypedArray<double> timeout_mda = context.inputs[0];
        auto timeout = std::chrono::microseconds(timeout_mda[0]);
        context.outputs[0] = factory.createScalar(static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).ForceFlush(timeout));
    }
}


} // namespace libmexclass::opentelemetry
