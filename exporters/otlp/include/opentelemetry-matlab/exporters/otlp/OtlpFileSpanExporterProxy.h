// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SpanExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/exporter.h"
#include "opentelemetry/exporters/otlp/otlp_file_exporter_options.h"

namespace trace_sdk = opentelemetry::sdk::trace;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpFileSpanExporterProxy: public libmexclass::opentelemetry::sdk::SpanExporterProxy {
  public:
    OtlpFileSpanExporterProxy(otlp_exporter::OtlpFileExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpFileSpanExporterProxy, setFileName);
        REGISTER_METHOD(OtlpFileSpanExporterProxy, setAliasName);
        REGISTER_METHOD(OtlpFileSpanExporterProxy, setFlushInterval);
        REGISTER_METHOD(OtlpFileSpanExporterProxy, setFlushRecordCount);
        REGISTER_METHOD(OtlpFileSpanExporterProxy, setMaxFileSize);
        REGISTER_METHOD(OtlpFileSpanExporterProxy, setMaxFileCount);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<trace_sdk::SpanExporter> getInstance() override;

    void setFileName(libmexclass::proxy::method::Context& context);

    void setAliasName(libmexclass::proxy::method::Context& context);

    void setFlushInterval(libmexclass::proxy::method::Context& context);

    void setFlushRecordCount(libmexclass::proxy::method::Context& context);

    void setMaxFileSize(libmexclass::proxy::method::Context& context);

    void setMaxFileCount(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpFileExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
