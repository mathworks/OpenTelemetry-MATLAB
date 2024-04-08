// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/logs/LogRecordExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/logs/exporter.h"
#include "opentelemetry/exporters/otlp/otlp_grpc_log_record_exporter_options.h"

namespace logs_sdk = opentelemetry::sdk::logs;
namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
class OtlpGrpcLogRecordExporterProxy: public libmexclass::opentelemetry::sdk::LogRecordExporterProxy {
  public:
    OtlpGrpcLogRecordExporterProxy(otlp_exporter::OtlpGrpcLogRecordExporterOptions options) : CppOptions(options) {
        REGISTER_METHOD(OtlpGrpcLogRecordExporterProxy, setEndpoint);
        REGISTER_METHOD(OtlpGrpcLogRecordExporterProxy, setUseCredentials);
        REGISTER_METHOD(OtlpGrpcLogRecordExporterProxy, setCertificatePath);
        REGISTER_METHOD(OtlpGrpcLogRecordExporterProxy, setCertificateString);
        REGISTER_METHOD(OtlpGrpcLogRecordExporterProxy, setTimeout);
        REGISTER_METHOD(OtlpGrpcLogRecordExporterProxy, setHttpHeaders);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<logs_sdk::LogRecordExporter> getInstance() override;

    void setEndpoint(libmexclass::proxy::method::Context& context);
    void setUseCredentials(libmexclass::proxy::method::Context& context);
    void setCertificatePath(libmexclass::proxy::method::Context& context);
    void setCertificateString(libmexclass::proxy::method::Context& context);
    void setTimeout(libmexclass::proxy::method::Context& context);
    void setHttpHeaders(libmexclass::proxy::method::Context& context);

  private:
    otlp_exporter::OtlpGrpcLogRecordExporterOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
