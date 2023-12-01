// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class ObservableGaugeProxy : public AsynchronousInstrumentProxy {
  public:
    ObservableGaugeProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> g) : AsynchronousInstrumentProxy(g) {
        REGISTER_METHOD(ObservableGaugeProxy, addCallback);
        REGISTER_METHOD(ObservableGaugeProxy, removeCallback);
    }
}; 
} // namespace libmexclass::opentelemetry


