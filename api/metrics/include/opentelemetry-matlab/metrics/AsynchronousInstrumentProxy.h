// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/metrics/async_instruments.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class AsynchronousInstrumentProxy : public libmexclass::proxy::Proxy {
  protected:
    AsynchronousInstrumentProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> inst) : CppInstrument(inst) {}

  public:
    void addCallback(libmexclass::proxy::method::Context& context);

    void removeCallback(libmexclass::proxy::method::Context& context);

    std::list<std::string> CallbackFunctions;

  private:
    nostd::shared_ptr<metrics_api::ObservableInstrument> CppInstrument;

}; 
} // namespace libmexclass::opentelemetry


