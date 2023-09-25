// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/metrics/push_metric_exporter.h"
#include "opentelemetry/exporters/otlp/otlp_grpc_exporter_options.h"

namespace metric_sdk = opentelemetry::sdk::metric;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpGrpcMetricExporterProxy: public libmexclass::opentelemetry::sdk::MetricExporterProxy {
  public:
    OtlpGrpcMetricExporterProxy(otlp_exporter::OtlpGrpcExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpGrpcMetricExporterProxy, getDefaultOptionValues);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<metric_sdk::MetricExporter> getInstance() override;

    void getDefaultOptionValues(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpGrpcExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
