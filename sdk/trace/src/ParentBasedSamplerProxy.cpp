// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/ParentBasedSamplerProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/samplers/parent_factory.h"

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult ParentBasedSamplerProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> delegateid_mda = constructor_arguments[0];
    libmexclass::proxy::ID delegateid = delegateid_mda[0];
    return std::make_shared<ParentBasedSamplerProxy>(std::shared_ptr<trace_sdk::Sampler>(std::move(std::static_pointer_cast<SamplerProxy>(
        libmexclass::proxy::ProxyManager::getProxy(delegateid))->getInstance())));
}

std::unique_ptr<trace_sdk::Sampler> ParentBasedSamplerProxy::getInstance() {
    return trace_sdk::ParentBasedSamplerFactory::Create(DelegateSampler);
}
} // namespace libmexclass::opentelemetry
