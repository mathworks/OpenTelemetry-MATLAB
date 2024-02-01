// Copyright 2023-2024 The MathWorks, Inc.

#pragma once
#include <chrono>

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/metrics/meter.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {

enum class AsynchronousInstrumentType {ObservableCounter, ObservableUpDownCounter, ObservableGauge};

class AsynchronousInstrumentProxyFactory {
  public:
    AsynchronousInstrumentProxyFactory(nostd::shared_ptr<metrics_api::Meter> mt, 
                    const std::shared_ptr<matlab::engine::MATLABEngine> eng) 
            : CppMeter(mt), MexEngine(eng) {}

    std::shared_ptr<libmexclass::proxy::Proxy> create(AsynchronousInstrumentType type, 
		    const matlab::data::Array& callback, const std::string& name, const std::string& description, 
		    const std::string& unit, const std::chrono::milliseconds& timeout);

  private:

    nostd::shared_ptr<metrics_api::Meter> CppMeter;
    const std::shared_ptr<matlab::engine::MATLABEngine> MexEngine;  // used for feval on callbacks
};
} // namespace libmexclass::opentelemetry
