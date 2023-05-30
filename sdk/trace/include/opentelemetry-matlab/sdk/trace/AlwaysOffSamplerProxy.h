// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/samplers/always_off_factory.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class AlwaysOffSamplerProxy : public SamplerProxy {
  public:
    AlwaysOffSamplerProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {}

    std::unique_ptr<trace_sdk::Sampler> getInstance() override {
        return trace_sdk::AlwaysOffSamplerFactory::Create();
    }
};
} // namespace libmexclass::opentelemetry
