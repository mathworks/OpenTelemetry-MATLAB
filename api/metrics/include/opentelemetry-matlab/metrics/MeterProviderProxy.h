// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/meter_provider_factory.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"
#include "opentelemetry/metrics/meter_provider.h"
#include "opentelemetry/metrics/provider.h"
#include "opentelemetry/metrics/noop.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class MeterProviderProxy : public libmexclass::proxy::Proxy {
  public:
    MeterProviderProxy(nostd::shared_ptr<metrics_api::MeterProvider> mp) : CppMeterProvider(mp) {
        REGISTER_METHOD(MeterProviderProxy, getMeter);
        REGISTER_METHOD(MeterProviderProxy, setMeterProvider);
    }

    // Static make method should only be used by getMeterProvider. It gets the global instance 
    // instead of creating a new instance
    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<MeterProviderProxy>(metrics_api::Provider::GetMeterProvider());
    }

    void getMeter(libmexclass::proxy::method::Context& context);

    void setMeterProvider(libmexclass::proxy::method::Context& context);

    nostd::shared_ptr<metrics_api::MeterProvider> getInstance() {
        return CppMeterProvider;
    }

  protected:
    nostd::shared_ptr<metrics_api::MeterProvider> CppMeterProvider;
};
} // namespace libmexclass::opentelemetry
