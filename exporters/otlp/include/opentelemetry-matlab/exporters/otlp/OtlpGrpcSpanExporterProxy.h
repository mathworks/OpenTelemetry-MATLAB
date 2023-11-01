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
    OtlpGrpcSpanExporterProxy(otlp_exporter::OtlpGrpcExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpGrpcSpanExporterProxy, setEndpoint);
        REGISTER_METHOD(OtlpGrpcSpanExporterProxy, setUseCredentials);
        REGISTER_METHOD(OtlpGrpcSpanExporterProxy, setCertificatePath);
        REGISTER_METHOD(OtlpGrpcSpanExporterProxy, setCertificateString);
        REGISTER_METHOD(OtlpGrpcSpanExporterProxy, setTimeout);
        REGISTER_METHOD(OtlpGrpcSpanExporterProxy, setHttpHeaders);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<trace_sdk::SpanExporter> getInstance() override;

    void setEndpoint(libmexclass::proxy::method::Context& context);
    void setUseCredentials(libmexclass::proxy::method::Context& context);
    void setCertificatePath(libmexclass::proxy::method::Context& context);
    void setCertificateString(libmexclass::proxy::method::Context& context);
    void setTimeout(libmexclass::proxy::method::Context& context);
    void setHttpHeaders(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpGrpcExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
