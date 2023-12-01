// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class ObservableUpDownCounterProxy : public AsynchronousInstrumentProxy {
  public:
    ObservableUpDownCounterProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> ct) : AsynchronousInstrumentProxy(ct) {
        REGISTER_METHOD(ObservableUpDownCounterProxy, addCallback);
        REGISTER_METHOD(ObservableUpDownCounterProxy, removeCallback);
    }
}; 
} // namespace libmexclass::opentelemetry


