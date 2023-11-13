// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/metrics/CounterProxy.h"
#include "opentelemetry-matlab/metrics/HistogramProxy.h"
#include "opentelemetry-matlab/metrics/UpDownCounterProxy.h"

#include "opentelemetry/metrics/meter.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class MeterProxy : public libmexclass::proxy::Proxy {
  public:
    MeterProxy(nostd::shared_ptr<metrics_api::Meter> mt) : CppMeter(mt) {
        REGISTER_METHOD(MeterProxy, createCounter);
        REGISTER_METHOD(MeterProxy, createUpDownCounter);
        REGISTER_METHOD(MeterProxy, createHistogram);
    }

    void createCounter(libmexclass::proxy::method::Context& context);

    void createUpDownCounter(libmexclass::proxy::method::Context& context);

    void createHistogram(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<metrics_api::Meter> CppMeter;
};
} // namespace libmexclass::opentelemetry
