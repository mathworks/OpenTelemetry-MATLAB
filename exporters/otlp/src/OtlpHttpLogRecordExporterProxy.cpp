// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/exporters/otlp/OtlpHttpLogRecordExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/exporters/otlp/otlp_http_log_record_exporter_factory.h"

namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
libmexclass::proxy::MakeResult OtlpHttpLogRecordExporterProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    otlp_exporter::OtlpHttpLogRecordExporterOptions options;
    return std::make_shared<OtlpHttpLogRecordExporterProxy>(options);
}

std::unique_ptr<logs_sdk::LogRecordExporter> OtlpHttpLogRecordExporterProxy::getInstance() {
    return otlp_exporter::OtlpHttpLogRecordExporterFactory::Create(CppOptions);
}

void OtlpHttpLogRecordExporterProxy::setEndpoint(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray endpoint_mda = context.inputs[0];
    std::string endpoint = static_cast<std::string>(endpoint_mda[0]);

    if (!endpoint.empty()) {
        CppOptions.url = endpoint;
    } 
}

void OtlpHttpLogRecordExporterProxy::setFormat(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray dataformat_mda = context.inputs[0];
    std::string dataformat = static_cast<std::string>(dataformat_mda[0]);

    if (dataformat.compare("JSON") == 0) {
        CppOptions.content_type = otlp_exporter::HttpRequestContentType::kJson;
    } else if (dataformat.compare("binary") == 0) {
        CppOptions.content_type = otlp_exporter::HttpRequestContentType::kBinary;
    }
}

void OtlpHttpLogRecordExporterProxy::setJsonBytesMapping(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray json_bytes_mapping_mda = context.inputs[0];
    std::string json_bytes_mapping = static_cast<std::string>(json_bytes_mapping_mda[0]);

    if (json_bytes_mapping.compare("hex") == 0) {
        CppOptions.json_bytes_mapping = otlp_exporter::JsonBytesMappingKind::kHex;
    } else if (json_bytes_mapping.compare("hexId") == 0) {
        CppOptions.json_bytes_mapping = otlp_exporter::JsonBytesMappingKind::kHexId;
    } else if (json_bytes_mapping.compare("base64") == 0) {
        CppOptions.json_bytes_mapping = otlp_exporter::JsonBytesMappingKind::kBase64;
    }
}

void OtlpHttpLogRecordExporterProxy::setUseJsonName(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<bool> use_json_name_mda = context.inputs[0];
    CppOptions.use_json_name = use_json_name_mda[0];
}

void OtlpHttpLogRecordExporterProxy::setTimeout(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> timeout_mda = context.inputs[0];
    double timeout = timeout_mda[0];

    if (timeout >= 0) {
        CppOptions.timeout = std::chrono::milliseconds(static_cast<int64_t>(timeout));
    }
}

void OtlpHttpLogRecordExporterProxy::setHttpHeaders(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray headernames_mda = context.inputs[0];
    matlab::data::StringArray headervalues_mda = context.inputs[1];
    size_t nheaders = headernames_mda.getNumberOfElements();
    for (size_t i = 0; i < nheaders; ++i) {
        CppOptions.http_headers.insert(std::pair{static_cast<std::string>(headernames_mda[i]),
				static_cast<std::string>(headervalues_mda[i])});
    }
}
} // namespace libmexclass::opentelemetry
