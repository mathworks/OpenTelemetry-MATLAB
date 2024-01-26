// Copyright 2023-2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class ObservableGaugeProxy : public AsynchronousInstrumentProxy {
  public:
    ObservableGaugeProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> g, 
                    const std::shared_ptr<matlab::engine::MATLABEngine> eng) 
            : AsynchronousInstrumentProxy(g, eng) {
        REGISTER_METHOD(ObservableGaugeProxy, addCallback);
        REGISTER_METHOD(ObservableGaugeProxy, removeCallback);
    }
}; 
} // namespace libmexclass::opentelemetry


