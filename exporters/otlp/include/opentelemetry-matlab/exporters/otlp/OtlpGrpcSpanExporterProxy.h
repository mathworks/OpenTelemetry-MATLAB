// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SpanExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/exporter.h"
#include "opentelemetry/exporters/otlp/otlp_grpc_exporter_options.h"

namespace trace_sdk = opentelemetry::sdk::trace;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpGrpcSpanExporterProxy: public libmexclass::opentelemetry::sdk::SpanExporterProxy {
  public:
    OtlpGrpcSpanExporterProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<trace_sdk::SpanExporter> getInstance();

    void getDefaultOptionValues(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpGrpcExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
