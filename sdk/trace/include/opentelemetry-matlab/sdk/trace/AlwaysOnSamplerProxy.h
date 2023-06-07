// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/samplers/always_on_factory.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class AlwaysOnSamplerProxy : public SamplerProxy {
  public:
    AlwaysOnSamplerProxy() {}

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<AlwaysOnSamplerProxy>();
    }

    std::unique_ptr<trace_sdk::Sampler> getInstance() override {
        return trace_sdk::AlwaysOnSamplerFactory::Create();
    }
};
} // namespace libmexclass::opentelemetry
