// Copyright 2023-2024 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/sdk/trace/SpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"
#include "opentelemetry-matlab/sdk/common/resource.h"
#include "opentelemetry-matlab/common/attribute.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/sdk/trace/tracer_provider.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/trace/tracer_provider.h"
#include "opentelemetry/trace/noop.h"
#include "opentelemetry/common/key_value_iterable_view.h"
#include "opentelemetry/nostd/shared_ptr.h"

namespace trace_api = opentelemetry::trace;
namespace trace_sdk = opentelemetry::sdk::trace;
namespace resource = opentelemetry::sdk::resource;
namespace common_sdk = opentelemetry::sdk::common;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult TracerProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    libmexclass::proxy::MakeResult out;
    if (constructor_arguments.getNumberOfElements() == 1) {
       // if only one input, assume it is an API Tracer Provider to support type conversion
       matlab::data::TypedArray<uint64_t> tpid_mda = constructor_arguments[0];
       libmexclass::proxy::ID tpid = tpid_mda[0];
       auto tp = std::static_pointer_cast<libmexclass::opentelemetry::TracerProviderProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(tpid))->getInstance();
       // check if input can be cast to an SDK Tracer Provider 
       auto tpsdk = dynamic_cast<trace_sdk::TracerProvider*>(tp.get());
       if (tpsdk == nullptr) {
          return libmexclass::error::Error{"opentelemetry:sdk:trace:Cleanup:UnsetGlobalInstance", 
		  "Clean up operations are not supported if global TracerProvider instance is not set."};
       }
       out = std::make_shared<TracerProviderProxy>(nostd::shared_ptr<trace_api::TracerProvider>(tp));
    } else {
       matlab::data::TypedArray<uint64_t> processorid_mda = constructor_arguments[0];
       libmexclass::proxy::ID processorid = processorid_mda[0];
       matlab::data::TypedArray<uint64_t> samplerid_mda = constructor_arguments[1];
       libmexclass::proxy::ID samplerid = samplerid_mda[0];
       matlab::data::StringArray resourcenames_mda = constructor_arguments[2];
       size_t nresourceattrs = resourcenames_mda.getNumberOfElements();
       matlab::data::CellArray resourcevalues_mda = constructor_arguments[3];

       auto processor = std::static_pointer_cast<SpanProcessorProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(processorid))->getInstance();
       auto sampler = std::static_pointer_cast<SamplerProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(samplerid))->getInstance();
    
       auto resource_custom = createResource(resourcenames_mda, resourcevalues_mda);

       std::unique_ptr<trace_sdk::TracerProvider> p_sdk = trace_sdk::TracerProviderFactory::Create(std::move(processor), 
		       resource_custom, std::move(sampler));
       nostd::shared_ptr<trace_sdk::TracerProvider> p_sdk_shared(std::move(p_sdk));
       nostd::shared_ptr<trace_api::TracerProvider> p_api_shared(std::move(p_sdk_shared));
       out = std::make_shared<TracerProviderProxy>(p_api_shared);
    }
    return out;
}

void TracerProviderProxy::addSpanProcessor(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> processorid_mda = context.inputs[0];
    libmexclass::proxy::ID processorid = processorid_mda[0];

    static_cast<trace_sdk::TracerProvider&>(*CppTracerProvider).AddProcessor(
		    std::static_pointer_cast<SpanProcessorProxy>(
			    libmexclass::proxy::ProxyManager::getProxy(processorid))->getInstance());
}

void TracerProviderProxy::shutdown(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;
    auto result_mda = factory.createScalar(static_cast<trace_sdk::TracerProvider&>(*CppTracerProvider).Shutdown());
    context.outputs[0] = result_mda;
    nostd::shared_ptr<trace_api::TracerProvider> noop(new trace_api::NoopTracerProvider);
    CppTracerProvider.swap(noop);
}

void TracerProviderProxy::forceFlush(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;

    if (context.inputs.getNumberOfElements() == 0) {
        context.outputs[0] = factory.createScalar(static_cast<trace_sdk::TracerProvider&>(*CppTracerProvider).ForceFlush());
    } else {  // number of inputs > 0
        matlab::data::TypedArray<double> timeout_mda = context.inputs[0];
        auto timeout = std::chrono::microseconds(timeout_mda[0]);
        context.outputs[0] = factory.createScalar(static_cast<trace_sdk::TracerProvider&>(*CppTracerProvider).ForceFlush(timeout));
    }
}

} // namespace libmexclass::opentelemetry
