// Copyright 2023-2024 The MathWorks, Inc.

#pragma once

#include <list>
#include <chrono>

#include "opentelemetry-matlab/metrics/AsynchronousCallbackInput.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/metrics/async_instruments.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class AsynchronousInstrumentProxy : public libmexclass::proxy::Proxy {
  protected:
    AsynchronousInstrumentProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> inst, 
                    const std::shared_ptr<matlab::engine::MATLABEngine> eng) : CppInstrument(inst), MexEngine(eng) {}

  public:
    void addCallback(libmexclass::proxy::method::Context& context);

    // This method should ideally be an overloaded version of addCallback. However, addCallback is a registered 
    // method and REGISTER_METHOD macro doesn't like overloaded methods. Rename to avoid overloading.
    void addCallback_helper(const matlab::data::Array& callback, const std::chrono::milliseconds& timeout);

    void removeCallback(libmexclass::proxy::method::Context& context);

  private:
    nostd::shared_ptr<metrics_api::ObservableInstrument> CppInstrument;

    std::list<AsynchronousCallbackInput> CallbackInputs;

    const std::shared_ptr<matlab::engine::MATLABEngine> MexEngine;  // used for feval on callbacks
}; 
} // namespace libmexclass::opentelemetry


