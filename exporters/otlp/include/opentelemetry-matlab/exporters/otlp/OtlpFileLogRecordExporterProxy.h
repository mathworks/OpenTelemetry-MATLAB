// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/logs/LogRecordExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/logs/exporter.h"
#include "opentelemetry/exporters/otlp/otlp_file_log_record_exporter_options.h"

namespace logs_sdk = opentelemetry::sdk::logs;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpFileLogRecordExporterProxy: public libmexclass::opentelemetry::sdk::LogRecordExporterProxy {
  public:
    OtlpFileLogRecordExporterProxy(otlp_exporter::OtlpFileLogRecordExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpFileLogRecordExporterProxy, setFileName);
        REGISTER_METHOD(OtlpFileLogRecordExporterProxy, setAliasName);
        REGISTER_METHOD(OtlpFileLogRecordExporterProxy, setFlushInterval);
        REGISTER_METHOD(OtlpFileLogRecordExporterProxy, setFlushRecordCount);
        REGISTER_METHOD(OtlpFileLogRecordExporterProxy, setMaxFileSize);
        REGISTER_METHOD(OtlpFileLogRecordExporterProxy, setMaxFileCount);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<logs_sdk::LogRecordExporter> getInstance() override;

    void setFileName(libmexclass::proxy::method::Context& context);

    void setAliasName(libmexclass::proxy::method::Context& context);

    void setFlushInterval(libmexclass::proxy::method::Context& context);

    void setFlushRecordCount(libmexclass::proxy::method::Context& context);

    void setMaxFileSize(libmexclass::proxy::method::Context& context);

    void setMaxFileCount(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpFileLogRecordExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
