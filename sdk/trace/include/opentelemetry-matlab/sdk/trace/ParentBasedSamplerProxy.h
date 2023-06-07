// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class ParentBasedSamplerProxy : public SamplerProxy {
  public:
    ParentBasedSamplerProxy(std::shared_ptr<trace_sdk::Sampler> delegate) 
	    : DelegateSampler(delegate) {}

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<trace_sdk::Sampler> getInstance() override;

  private:
    std::shared_ptr<trace_sdk::Sampler> DelegateSampler;
};
} // namespace libmexclass::opentelemetry
