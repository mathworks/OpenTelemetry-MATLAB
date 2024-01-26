// Copyright 2023-2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class ObservableUpDownCounterProxy : public AsynchronousInstrumentProxy {
  public:
    ObservableUpDownCounterProxy(nostd::shared_ptr<metrics_api::ObservableInstrument> ct, 
                    const std::shared_ptr<matlab::engine::MATLABEngine> eng) 
            : AsynchronousInstrumentProxy(ct, eng) {
        REGISTER_METHOD(ObservableUpDownCounterProxy, addCallback);
        REGISTER_METHOD(ObservableUpDownCounterProxy, removeCallback);
    }
}; 
} // namespace libmexclass::opentelemetry


