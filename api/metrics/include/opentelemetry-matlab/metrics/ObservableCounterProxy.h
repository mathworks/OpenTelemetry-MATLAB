// Copyright 2023-2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class ObservableCounterProxy : public AsynchronousInstrumentProxy {
  public:
    ObservableCounterProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> ct, 
                    const std::shared_ptr<matlab::engine::MATLABEngine> eng) 
            : AsynchronousInstrumentProxy(ct, eng) {
        REGISTER_METHOD(ObservableCounterProxy, addCallback);
        REGISTER_METHOD(ObservableCounterProxy, removeCallback);
    }
}; 
} // namespace libmexclass::opentelemetry


