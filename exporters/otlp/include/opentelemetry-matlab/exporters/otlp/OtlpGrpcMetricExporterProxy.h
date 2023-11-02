// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/push_metric_exporter.h"
#include "opentelemetry/exporters/otlp/otlp_grpc_metric_exporter_options.h"

namespace metric_sdk = opentelemetry::sdk::metrics;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpGrpcMetricExporterProxy: public libmexclass::opentelemetry::sdk::MetricExporterProxy {
  public:
    OtlpGrpcMetricExporterProxy(otlp_exporter::OtlpGrpcMetricExporterOptions options) : CppOptions(options) {
	REGISTER_METHOD(OtlpGrpcMetricExporterProxy, setEndpoint);
        REGISTER_METHOD(OtlpGrpcMetricExporterProxy, setUseCredentials);
        REGISTER_METHOD(OtlpGrpcMetricExporterProxy, setCertificatePath);
        REGISTER_METHOD(OtlpGrpcMetricExporterProxy, setCertificateString);
        REGISTER_METHOD(OtlpGrpcMetricExporterProxy, setTimeout);
        REGISTER_METHOD(OtlpGrpcMetricExporterProxy, setHttpHeaders);
        REGISTER_METHOD(OtlpGrpcMetricExporterProxy, setTemporality);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metric_sdk::PushMetricExporter> getInstance() override;

    void setEndpoint(libmexclass::proxy::method::Context& context);
    void setUseCredentials(libmexclass::proxy::method::Context& context);
    void setCertificatePath(libmexclass::proxy::method::Context& context);
    void setCertificateString(libmexclass::proxy::method::Context& context);
    void setTimeout(libmexclass::proxy::method::Context& context);
    void setHttpHeaders(libmexclass::proxy::method::Context& context);
    void setTemporality(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpGrpcMetricExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
