// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/logs/LoggerProviderProxy.h"
#include "opentelemetry-matlab/sdk/logs/LogRecordProcessorProxy.h"
#include "opentelemetry-matlab/sdk/common/resource.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/logs/logger_provider_factory.h"
#include "opentelemetry/sdk/logs/logger_provider.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/logs/logger_provider.h"
#include "opentelemetry/logs/noop.h"
#include "opentelemetry/common/key_value_iterable_view.h"

namespace logs_api = opentelemetry::logs;
namespace logs_sdk = opentelemetry::sdk::logs;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult LoggerProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    libmexclass::proxy::MakeResult out;
    if (constructor_arguments.getNumberOfElements() == 1) {
       // if only one input, assume it is an API Logger Provider to support type conversion
       matlab::data::TypedArray<uint64_t> lpid_mda = constructor_arguments[0];
       libmexclass::proxy::ID lpid = lpid_mda[0];
       auto lp = std::static_pointer_cast<libmexclass::opentelemetry::LoggerProviderProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(lpid))->getInstance();
       // check if input can be cast to an SDK Logger Provider 
       auto lpsdk = dynamic_cast<logs_sdk::LoggerProvider*>(lp.get());
       if (lpsdk == nullptr) {
          return libmexclass::error::Error{"opentelemetry:sdk:logs:Cleanup:UnsetGlobalInstance", 
		  "Clean up operations are not supported if global LoggerProvider instance is not set."};
       }
       out = std::make_shared<LoggerProviderProxy>(nostd::shared_ptr<logs_api::LoggerProvider>(lp));
    } else {
       matlab::data::TypedArray<uint64_t> processorid_mda = constructor_arguments[0];
       libmexclass::proxy::ID processorid = processorid_mda[0];
       matlab::data::StringArray resourcenames_mda = constructor_arguments[1];
       size_t nresourceattrs = resourcenames_mda.getNumberOfElements();
       matlab::data::CellArray resourcevalues_mda = constructor_arguments[2];

       auto processor = std::static_pointer_cast<LogRecordProcessorProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(processorid))->getInstance();
    
       auto resource_custom = createResource(resourcenames_mda, resourcevalues_mda);

       std::unique_ptr<logs_sdk::LoggerProvider> p_sdk = logs_sdk::LoggerProviderFactory::Create(
				       std::move(processor), resource_custom);
       nostd::shared_ptr<logs_sdk::LoggerProvider> p_sdk_shared(std::move(p_sdk));
       nostd::shared_ptr<logs_api::LoggerProvider> p_api_shared(std::move(p_sdk_shared));
       out = std::make_shared<LoggerProviderProxy>(p_api_shared);
    }
    return out;
}

void LoggerProviderProxy::addProcessor(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> processorid_mda = context.inputs[0];
    libmexclass::proxy::ID processorid = processorid_mda[0];

    static_cast<logs_sdk::LoggerProvider&>(*CppLoggerProvider).AddProcessor(
		    std::static_pointer_cast<LogRecordProcessorProxy>(
			    libmexclass::proxy::ProxyManager::getProxy(processorid))->getInstance());
}

void LoggerProviderProxy::shutdown(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;
    auto result_mda = factory.createScalar(static_cast<logs_sdk::LoggerProvider&>(*CppLoggerProvider).Shutdown());
    context.outputs[0] = result_mda;
    nostd::shared_ptr<logs_api::LoggerProvider> noop(new logs_api::NoopLoggerProvider);
    CppLoggerProvider.swap(noop);
}

void LoggerProviderProxy::forceFlush(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;

    if (context.inputs.getNumberOfElements() == 0) {
        context.outputs[0] = factory.createScalar(static_cast<logs_sdk::LoggerProvider&>(*CppLoggerProvider).ForceFlush());
    } else {  // number of inputs > 0
        matlab::data::TypedArray<double> timeout_mda = context.inputs[0];
        auto timeout = std::chrono::microseconds(timeout_mda[0]);
        context.outputs[0] = factory.createScalar(static_cast<logs_sdk::LoggerProvider&>(*CppLoggerProvider).ForceFlush(timeout));
    }
}
} // namespace libmexclass::opentelemetry
