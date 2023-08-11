// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/metrics/meter.h"
#include "opentelemetry/metrics/sync_instruments.h"


namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class CounterProxy : public libmexclass::proxy::Proxy {
  public:
    CounterProxy(nostd::shared_ptr<metrics_api::Counter<double> > counter) {
       CppCounter = std::move(counter);
       REGISTER_METHOD(CounterProxy, add);
    }

    void add(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<metrics_api::Counter<double> > CppCounter;

}; 
} // namespace libmexclass::opentelemetry


