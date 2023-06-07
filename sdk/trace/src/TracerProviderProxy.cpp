// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/sdk/trace/SpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"
#include "opentelemetry-matlab/trace/attribute.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/sdk/trace/tracer_provider.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/trace/tracer_provider.h"
#include "opentelemetry/common/key_value_iterable_view.h"

namespace trace_api = opentelemetry::trace;
namespace trace_sdk = opentelemetry::sdk::trace;
namespace resource = opentelemetry::sdk::resource;
namespace common_sdk = opentelemetry::sdk::common;

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult TracerProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
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
    
    // resource
    std::list<std::pair<std::string, common::AttributeValue> > resourceattrs;
    std::list<std::vector<double> > resourcedims_double; // list of vector, to hold the dimensions of array attributes 
    std::list<std::string> string_resource_attrs; // list of strings as a buffer to hold the string attributes
    std::list<std::vector<nostd::string_view> > stringview_resource_attrs; // list of vector of stringviews, used for string array attributes only
    for (size_t i = 0; i < nresourceattrs; ++i) {
       std::string resourcename = static_cast<std::string>(resourcenames_mda[i]);
       matlab::data::Array resourcevalue = resourcevalues_mda[i];

       processAttribute(resourcename, resourcevalue, resourceattrs, string_resource_attrs, stringview_resource_attrs, resourcedims_double);
    }
    auto resource_default = resource::Resource::Create({ {"telemetry.sdk.language", "MATLAB"},
		    {"telemetry.sdk.version", OTEL_MATLAB_VERSION} });
    auto resource_custom = resource::Resource::Create(common::KeyValueIterableView{resourceattrs});
    // the order matters, default resource must come after custom. Otherwise the default resource will be overwritten.
    auto resource_merged = resource_custom.Merge(resource_default);  

    return std::make_shared<TracerProviderProxy>(nostd::shared_ptr<trace_api::TracerProvider>(
		    std::move(trace_sdk::TracerProviderFactory::Create(std::move(processor), resource_merged,
		    std::move(sampler)))));
}

void TracerProviderProxy::addSpanProcessor(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> processorid_mda = context.inputs[0];
    libmexclass::proxy::ID processorid = processorid_mda[0];

    static_cast<trace_sdk::TracerProvider&>(*CppTracerProvider).AddProcessor(
		    std::static_pointer_cast<SpanProcessorProxy>(
			    libmexclass::proxy::ProxyManager::getProxy(processorid))->getInstance());
}

} // namespace libmexclass::opentelemetry
