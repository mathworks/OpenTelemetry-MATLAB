// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/push_metric_exporter.h"
#include "opentelemetry/exporters/otlp/otlp_http_metric_exporter_options.h"

namespace metric_sdk = opentelemetry::sdk::metrics;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpHttpMetricExporterProxy: public libmexclass::opentelemetry::sdk::MetricExporterProxy {
  public:
    OtlpHttpMetricExporterProxy(otlp_exporter::OtlpHttpMetricExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, setEndpoint);
	REGISTER_METHOD(OtlpHttpMetricExporterProxy, setFormat);
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, setJsonBytesMapping);
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, setUseJsonName);
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, setTimeout);
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, setHttpHeaders);
        REGISTER_METHOD(OtlpHttpMetricExporterProxy, setTemporality);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metric_sdk::PushMetricExporter> getInstance() override;

    void setEndpoint(libmexclass::proxy::method::Context& context);
    void setFormat(libmexclass::proxy::method::Context& context);
    void setJsonBytesMapping(libmexclass::proxy::method::Context& context);
    void setUseJsonName(libmexclass::proxy::method::Context& context);
    void setTimeout(libmexclass::proxy::method::Context& context);
    void setHttpHeaders(libmexclass::proxy::method::Context& context);
    void setTemporality(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpHttpMetricExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
