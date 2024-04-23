// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/exporters/otlp/OtlpGrpcLogRecordExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/exporters/otlp/otlp_grpc_log_record_exporter_factory.h"

namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
libmexclass::proxy::MakeResult OtlpGrpcLogRecordExporterProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    otlp_exporter::OtlpGrpcLogRecordExporterOptions options;
    return std::make_shared<OtlpGrpcLogRecordExporterProxy>(options);
}

std::unique_ptr<logs_sdk::LogRecordExporter> OtlpGrpcLogRecordExporterProxy::getInstance() {
    return otlp_exporter::OtlpGrpcLogRecordExporterFactory::Create(CppOptions);
}

void OtlpGrpcLogRecordExporterProxy::setEndpoint(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray endpoint_mda = context.inputs[0];
    std::string endpoint = static_cast<std::string>(endpoint_mda[0]);

    if (!endpoint.empty()) {
        CppOptions.endpoint = endpoint;
    }
}


void OtlpGrpcLogRecordExporterProxy::setUseCredentials(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<bool> use_credentials_mda = context.inputs[0];
    CppOptions.use_ssl_credentials = use_credentials_mda[0];
}

void OtlpGrpcLogRecordExporterProxy::setCertificatePath(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray certpath_mda = context.inputs[0];
    std::string certpath = static_cast<std::string>(certpath_mda[0]);

    if (!certpath.empty()) {
        CppOptions.ssl_credentials_cacert_path = certpath;
    }
}

void OtlpGrpcLogRecordExporterProxy::setCertificateString(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray certstr_mda = context.inputs[0];
    std::string certstr = static_cast<std::string>(certstr_mda[0]);

    if (!certstr.empty()) {
        CppOptions.ssl_credentials_cacert_as_string = certstr;
    }
}

void OtlpGrpcLogRecordExporterProxy::setTimeout(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> timeout_mda = context.inputs[0];
    double timeout = timeout_mda[0];

    if (timeout >= 0) {
        CppOptions.timeout = std::chrono::milliseconds(static_cast<int64_t>(timeout));
    }
}

void OtlpGrpcLogRecordExporterProxy::setHttpHeaders(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray headernames_mda = context.inputs[0];
    matlab::data::StringArray headervalues_mda = context.inputs[1];
    size_t nheaders = headernames_mda.getNumberOfElements();
    for (size_t i = 0; i < nheaders; ++i) {
        CppOptions.metadata.insert(std::pair{static_cast<std::string>(headernames_mda[i]),
                                static_cast<std::string>(headervalues_mda[i])});
    }
}
} // namespace libmexclass::opentelemetry
