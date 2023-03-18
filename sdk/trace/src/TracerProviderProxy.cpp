// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/sdk/trace/SpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/trace/tracer_provider.h"

namespace trace_api = opentelemetry::trace;
namespace trace_sdk = opentelemetry::sdk::trace;
namespace nostd = opentelemetry::nostd;
namespace resource = opentelemetry::sdk::resource;

namespace libmexclass::opentelemetry::sdk {
TracerProviderProxy::TracerProviderProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> processorid_mda = constructor_arguments[0];
    libmexclass::proxy::ID processorid = processorid_mda[0];
    matlab::data::TypedArray<uint64_t> samplerid_mda = constructor_arguments[1];
    libmexclass::proxy::ID samplerid = samplerid_mda[0];

    auto processor = std::static_pointer_cast<SpanProcessorProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(processorid))->getInstance();
    auto sampler = std::static_pointer_cast<SamplerProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(samplerid))->getInstance();
    CppTracerProvider = nostd::shared_ptr<trace_api::TracerProvider>(
		    std::move(trace_sdk::TracerProviderFactory::Create(std::move(processor),
		    resource::Resource::Create({ {"telemetry.sdk.language", "MATLAB"}, 
			    {"telemetry.sdk.version", OTEL_MATLAB_VERSION} }),
		    std::move(sampler))));
}

} // namespace libmexclass::opentelemetry
