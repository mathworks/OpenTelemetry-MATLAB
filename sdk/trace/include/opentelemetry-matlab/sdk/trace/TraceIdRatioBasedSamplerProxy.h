// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SamplerProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/samplers/trace_id_ratio_factory.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class TraceIdRatioBasedSamplerProxy : public SamplerProxy {
  public:
    TraceIdRatioBasedSamplerProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        matlab::data::TypedArray<double> ratio_mda = constructor_arguments[0];
        Ratio = ratio_mda[0];
    }

    std::unique_ptr<trace_sdk::Sampler> getInstance() {
        return trace_sdk::TraceIdRatioBasedSamplerFactory::Create(Ratio);
    }

  private:
    double Ratio;
};
} // namespace libmexclass::opentelemetry
