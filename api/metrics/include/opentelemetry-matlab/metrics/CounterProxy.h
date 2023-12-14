// Copyright 2023 The MathWorks, Inc.

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
class CounterProxy : public libmexclass::proxy::Proxy {
  public:
    CounterProxy(nostd::shared_ptr<metrics_api::Counter<double> > ct) : CppCounter(ct) {
       REGISTER_METHOD(CounterProxy, processValue);
    }

    void processValue(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<metrics_api::Counter<double> > CppCounter;

}; 
} // namespace libmexclass::opentelemetry


