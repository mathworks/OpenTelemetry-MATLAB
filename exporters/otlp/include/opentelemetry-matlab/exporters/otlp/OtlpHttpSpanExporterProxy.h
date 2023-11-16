// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SpanExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/exporter.h"
#include "opentelemetry/exporters/otlp/otlp_http_exporter_options.h"

namespace trace_sdk = opentelemetry::sdk::trace;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpHttpSpanExporterProxy: public libmexclass::opentelemetry::sdk::SpanExporterProxy {
  public:
    OtlpHttpSpanExporterProxy(otlp_exporter::OtlpHttpExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpHttpSpanExporterProxy, setEndpoint);
        REGISTER_METHOD(OtlpHttpSpanExporterProxy, setFormat);
        REGISTER_METHOD(OtlpHttpSpanExporterProxy, setJsonBytesMapping);
        REGISTER_METHOD(OtlpHttpSpanExporterProxy, setUseJsonName);
        REGISTER_METHOD(OtlpHttpSpanExporterProxy, setTimeout);
        REGISTER_METHOD(OtlpHttpSpanExporterProxy, setHttpHeaders);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<trace_sdk::SpanExporter> getInstance() override;

    void setEndpoint(libmexclass::proxy::method::Context& context);

    void setFormat(libmexclass::proxy::method::Context& context);

    void setJsonBytesMapping(libmexclass::proxy::method::Context& context);

    void setUseJsonName(libmexclass::proxy::method::Context& context);

    void setTimeout(libmexclass::proxy::method::Context& context);

    void setHttpHeaders(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpHttpExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
