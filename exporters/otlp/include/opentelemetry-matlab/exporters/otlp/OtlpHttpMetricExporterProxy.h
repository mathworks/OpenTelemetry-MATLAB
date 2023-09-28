// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/push_metric_exporter.h"
<<<<<<< Updated upstream
#include "opentelemetry/exporters/otlp/otlp_http_exporter_options.h"
=======
#include "opentelemetry/exporters/otlp/otlp_http_metric_exporter_options.h"
>>>>>>> Stashed changes

namespace metric_sdk = opentelemetry::sdk::metrics;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpHttpMetricExporterProxy: public libmexclass::opentelemetry::sdk::MetricExporterProxy {
  public:
<<<<<<< Updated upstream
    OtlpHttpMetricExporterProxy(otlp_exporter::OtlpHttpExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, getDefaultOptionValues);
=======
    OtlpHttpMetricExporterProxy(otlp_exporter::OtlpHttpMetricExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, getDefaultOptionValues);
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, test);
>>>>>>> Stashed changes
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metric_sdk::PushMetricExporter> getInstance() override;

    void getDefaultOptionValues(libmexclass::proxy::method::Context& context);

<<<<<<< Updated upstream
  private:
    otlp_exporter::OtlpHttpExporterOptions CppOptions;
=======
    void test(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpHttpMetricExporterOptions CppOptions;
>>>>>>> Stashed changes
};
} // namespace libmexclass::opentelemetry
