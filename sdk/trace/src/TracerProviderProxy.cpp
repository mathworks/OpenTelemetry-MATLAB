// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/sdk/trace/SpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"
#include "opentelemetry-matlab/trace/attribute.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/trace/tracer_provider.h"
#include "opentelemetry/common/key_value_iterable_view.h"

namespace trace_api = opentelemetry::trace;
namespace trace_sdk = opentelemetry::sdk::trace;
namespace nostd = opentelemetry::nostd;
namespace resource = opentelemetry::sdk::resource;
namespace common_sdk = opentelemetry::sdk::common;

namespace libmexclass::opentelemetry::sdk {
TracerProviderProxy::TracerProviderProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> processorid_mda = constructor_arguments[0];
    libmexclass::proxy::ID processorid = processorid_mda[0];
    matlab::data::TypedArray<uint64_t> samplerid_mda = constructor_arguments[1];
    libmexclass::proxy::ID samplerid = samplerid_mda[0];
    matlab::data::StringArray resourcenames_mda = constructor_arguments[2];
    matlab::data::Array resourcenames_base_mda = constructor_arguments[2];
    size_t nresourceattrs = resourcenames_base_mda.getNumberOfElements();
    matlab::data::CellArray resourcevalues_mda = constructor_arguments[3];

    auto processor = std::static_pointer_cast<SpanProcessorProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(processorid))->getInstance();
    auto sampler = std::static_pointer_cast<SamplerProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(samplerid))->getInstance();
    
    // resource
    std::vector<std::pair<std::string, common::AttributeValue> > resourceattrs;
    // TODO Use one level of std::vector instead of 2
    std::vector<std::vector<double> > resourcedims_double; // vector of vector, to hold the dimensions of array attributes 
    for (size_t i = 0; i < nresourceattrs; ++i) {
       std::string resourcename = static_cast<std::string>(resourcenames_mda[i]);
       matlab::data::Array resourcevalue = resourcevalues_mda[i];

       processAttribute(resourcename, resourcevalue, resourceattrs, resourcedims_double);
    }
    auto resource_default = resource::Resource::Create({ {"telemetry.sdk.language", "MATLAB"},
		    {"telemetry.sdk.version", OTEL_MATLAB_VERSION} });
    auto resource_custom = resource::Resource::Create(common::KeyValueIterableView{resourceattrs});
    auto resource_merged = resource_default.Merge(resource_custom);

    CppTracerProvider = nostd::shared_ptr<trace_api::TracerProvider>(
		    std::move(trace_sdk::TracerProviderFactory::Create(std::move(processor), resource_merged,
		    std::move(sampler))));
}

} // namespace libmexclass::opentelemetry
