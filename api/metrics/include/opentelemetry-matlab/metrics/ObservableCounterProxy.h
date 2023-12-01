// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class ObservableCounterProxy : public AsynchronousInstrumentProxy {
  public:
    ObservableCounterProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> ct) : AsynchronousInstrumentProxy(ct) {
        REGISTER_METHOD(ObservableCounterProxy, addCallback);
        REGISTER_METHOD(ObservableCounterProxy, removeCallback);
    }
}; 
} // namespace libmexclass::opentelemetry


