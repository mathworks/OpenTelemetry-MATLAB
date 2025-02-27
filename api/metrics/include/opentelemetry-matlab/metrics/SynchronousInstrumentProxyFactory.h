// Copyright 2023-2025 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/metrics/meter.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {

enum class SynchronousInstrumentType {Counter, UpDownCounter, Histogram, Gauge};

class SynchronousInstrumentProxyFactory {
  public:
    SynchronousInstrumentProxyFactory(nostd::shared_ptr<metrics_api::Meter> mt) : CppMeter(mt) {}

    std::shared_ptr<libmexclass::proxy::Proxy> create(SynchronousInstrumentType type, 
		    const std::string& name, const std::string& description, const std::string& unit);

  private:

    nostd::shared_ptr<metrics_api::Meter> CppMeter;
};
} // namespace libmexclass::opentelemetry
