// Copyright 2023-2024 The MathWorks, Inc.

#pragma once

#include <list>

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

    // This method should ideally be an overloaded version of addCallback. However, addCallback is a registered 
    // method and REGISTER_METHOD macro doesn't like overloaded methods. Rename to avoid overloading.
    void addCallback_helper(const matlab::data::Array& callback);

    void removeCallback(libmexclass::proxy::method::Context& context);

  private:
    nostd::shared_ptr<metrics_api::ObservableInstrument> CppInstrument;

    std::list<matlab::data::Array> CallbackFunctions;

}; 
} // namespace libmexclass::opentelemetry


