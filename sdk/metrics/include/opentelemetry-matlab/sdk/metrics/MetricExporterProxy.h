// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/sdk/metrics/push_metric_exporter.h"

namespace metric_sdk = opentelemetry::sdk::metric;

namespace libmexclass::opentelemetry::sdk {
class MetricExporterProxy : public libmexclass::proxy::Proxy {
  public:
    virtual std::unique_ptr<metric_sdk::PushMetricExporter> getInstance() = 0;
};
} // namespace libmexclass::opentelemetry
