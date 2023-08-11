// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/metrics/meter.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class MeterProxy : public libmexclass::proxy::Proxy {
  public:
    MeterProxy(nostd::shared_ptr<metrics_api::Meter> mt) : CppMeter(mt) {
        REGISTER_METHOD(MeterProxy, createCounter);
    }

    void createCounter(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<metrics_api::Meter> CppMeter;
};
} // namespace libmexclass::opentelemetry
