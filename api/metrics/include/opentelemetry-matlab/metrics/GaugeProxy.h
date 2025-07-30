// Copyright 2025 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/metrics/meter.h"
#include "opentelemetry/metrics/sync_instruments.h"

#include "opentelemetry-matlab/common/attribute.h"
#include "opentelemetry-matlab/common/ProcessedAttributes.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class GaugeProxy : public libmexclass::proxy::Proxy {
  public:
    GaugeProxy(nostd::shared_ptr<metrics_api::Gauge<double> > g) : CppGauge(g) {
       REGISTER_METHOD(GaugeProxy, processValue);
    }

    void processValue(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<metrics_api::Gauge<double> > CppGauge;

}; 
} // namespace libmexclass::opentelemetry


