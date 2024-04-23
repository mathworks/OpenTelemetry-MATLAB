// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/logs/LogRecordExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/logs/exporter.h"
#include "opentelemetry/exporters/otlp/otlp_http_log_record_exporter_options.h"

namespace logs_sdk = opentelemetry::sdk::logs;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpHttpLogRecordExporterProxy: public libmexclass::opentelemetry::sdk::LogRecordExporterProxy {
  public:
    OtlpHttpLogRecordExporterProxy(otlp_exporter::OtlpHttpLogRecordExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpHttpLogRecordExporterProxy, setEndpoint);
        REGISTER_METHOD(OtlpHttpLogRecordExporterProxy, setFormat);
        REGISTER_METHOD(OtlpHttpLogRecordExporterProxy, setJsonBytesMapping);
        REGISTER_METHOD(OtlpHttpLogRecordExporterProxy, setUseJsonName);
        REGISTER_METHOD(OtlpHttpLogRecordExporterProxy, setTimeout);
        REGISTER_METHOD(OtlpHttpLogRecordExporterProxy, setHttpHeaders);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<logs_sdk::LogRecordExporter> getInstance() override;

    void setEndpoint(libmexclass::proxy::method::Context& context);

    void setFormat(libmexclass::proxy::method::Context& context);

    void setJsonBytesMapping(libmexclass::proxy::method::Context& context);

    void setUseJsonName(libmexclass::proxy::method::Context& context);

    void setTimeout(libmexclass::proxy::method::Context& context);

    void setHttpHeaders(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpHttpLogRecordExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
