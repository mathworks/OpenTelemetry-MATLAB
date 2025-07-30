// Copyright 2025 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/metrics/meter_provider.h"
#include "opentelemetry/metrics/provider.h"
#include "opentelemetry/metrics/noop.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class NoOpMeterProviderProxy : public libmexclass::proxy::Proxy {
  public:
    NoOpMeterProviderProxy(nostd::shared_ptr<metrics_api::MeterProvider> mp) : CppMeterProvider(mp) {
        // set as global MeterProvider instance
        metrics_api::Provider::SetMeterProvider(CppMeterProvider);
    } 

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<NoOpMeterProviderProxy>(nostd::shared_ptr<metrics_api::MeterProvider>(new metrics_api::NoopMeterProvider()));
    }

  protected:
    nostd::shared_ptr<metrics_api::MeterProvider> CppMeterProvider;
};
} // namespace libmexclass::opentelemetry
