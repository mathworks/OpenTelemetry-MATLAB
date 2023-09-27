// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/export/periodic_exporting_metric_reader_factory.h"
#include "opentelemetry/sdk/metrics/export/periodic_exporting_metric_reader_options.h"

namespace metric_sdk = opentelemetry::sdk::metrics;

namespace libmexclass::opentelemetry::sdk {
class PeriodicExportingMetricReaderProxy : public libmexclass::proxy::Proxy {
  public:
    PeriodicExportingMetricReaderProxy(std::shared_ptr<MetricExporterProxy> exporter, double interval, double timeout);

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metric_sdk::MetricReader> getInstance();

    void getDefaultOptionValues(libmexclass::proxy::method::Context& context);

  private:
    metric_sdk::PeriodicExportingMetricReaderOptions CppOptions;

    std::shared_ptr<MetricExporterProxy> MetricExporter;
};
} // namespace libmexclass::opentelemetry
