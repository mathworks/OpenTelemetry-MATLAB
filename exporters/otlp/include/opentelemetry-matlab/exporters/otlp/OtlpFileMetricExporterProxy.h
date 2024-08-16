// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/push_metric_exporter.h"
#include "opentelemetry/exporters/otlp/otlp_file_metric_exporter_options.h"

namespace metric_sdk = opentelemetry::sdk::metrics;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpFileMetricExporterProxy: public libmexclass::opentelemetry::sdk::MetricExporterProxy {
  public:
    OtlpFileMetricExporterProxy(otlp_exporter::OtlpFileMetricExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpFileMetricExporterProxy, setFileName);
        REGISTER_METHOD(OtlpFileMetricExporterProxy, setAliasName);
        REGISTER_METHOD(OtlpFileMetricExporterProxy, setFlushInterval);
        REGISTER_METHOD(OtlpFileMetricExporterProxy, setFlushRecordCount);
        REGISTER_METHOD(OtlpFileMetricExporterProxy, setMaxFileSize);
        REGISTER_METHOD(OtlpFileMetricExporterProxy, setMaxFileCount);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metric_sdk::PushMetricExporter> getInstance() override;

    void setFileName(libmexclass::proxy::method::Context& context);

    void setAliasName(libmexclass::proxy::method::Context& context);

    void setFlushInterval(libmexclass::proxy::method::Context& context);

    void setFlushRecordCount(libmexclass::proxy::method::Context& context);

    void setMaxFileSize(libmexclass::proxy::method::Context& context);

    void setMaxFileCount(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpFileMetricExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
