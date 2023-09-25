// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/periodic_exporting_metric_reader_options.h"

namespace metric_reader_sdk = opentelemetry::sdk::metrics::MetricReader;

namespace libmexclass::opentelemetry::sdk {
class PeriodicExportingMetricReaderProxy : public libmexclass::proxy::Proxy {
  public:
    PeriodicExportingMetricReaderProxy(std::shared_ptr<MetricExporterProxy> exporter, double interval, double timeout);

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metric_reader_sdk::PeriodicExportingMetricReader> getInstance();

    void getDefaultOptionValues(libmexclass::proxy::method::Context& context);

  private:
    metric_reader_sdk::PeriodicExportingMetricReaderOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
