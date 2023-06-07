// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/exporters/otlp/OtlpHttpSpanExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"

namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
libmexclass::proxy::MakeResult OtlpHttpSpanExporterProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::StringArray endpoint_mda = constructor_arguments[0];
    std::string endpoint = static_cast<std::string>(endpoint_mda[0]);
    matlab::data::StringArray dataformat_mda = constructor_arguments[1];
    std::string dataformat = static_cast<std::string>(dataformat_mda[0]);
    matlab::data::StringArray json_bytes_mapping_mda = constructor_arguments[2];
    std::string json_bytes_mapping = static_cast<std::string>(json_bytes_mapping_mda[0]);
    matlab::data::TypedArray<bool> use_json_name_mda = constructor_arguments[3];
    bool use_json_name = use_json_name_mda[0];
    matlab::data::TypedArray<double> timeout_mda = constructor_arguments[4];
    double timeout = timeout_mda[0];
    matlab::data::Array header_mda = constructor_arguments[5];
    size_t nheaders = header_mda.getNumberOfElements();
    matlab::data::StringArray headernames_mda = constructor_arguments[5];
    matlab::data::StringArray headervalues_mda = constructor_arguments[6];

    otlp_exporter::OtlpHttpExporterOptions options;
    if (!endpoint.empty()) {
        options.url = endpoint;
    } 
    // TODO: store the relationship between strings and enums in an associative container
    // dataformat
    if (dataformat.compare("JSON") == 0) {
        options.content_type = otlp_exporter::HttpRequestContentType::kJson;
    } else if (dataformat.compare("binary") == 0) {
        options.content_type = otlp_exporter::HttpRequestContentType::kBinary;
    }
    // json_bytes_mapping
    if (json_bytes_mapping.compare("hex") == 0) {
        options.json_bytes_mapping = otlp_exporter::JsonBytesMappingKind::kHex;
    } else if (json_bytes_mapping.compare("hexId") == 0) {
        options.json_bytes_mapping = otlp_exporter::JsonBytesMappingKind::kHexId;
    } else if (json_bytes_mapping.compare("base64") == 0) {
        options.json_bytes_mapping = otlp_exporter::JsonBytesMappingKind::kBase64;
    }
    // use_json_name
    options.use_json_name = use_json_name;
    // timeout
    if (timeout >= 0) {
        options.timeout = std::chrono::milliseconds(static_cast<int64_t>(timeout));
    }
    // http headers
    for (size_t i = 0; i < nheaders; ++i) {
        options.http_headers.insert(std::pair{static_cast<std::string>(headernames_mda[i]),
				static_cast<std::string>(headervalues_mda[i])});
    }
    return std::make_shared<OtlpHttpSpanExporterProxy>(options);
}

std::unique_ptr<trace_sdk::SpanExporter> OtlpHttpSpanExporterProxy::getInstance() {
    return otlp_exporter::OtlpHttpExporterFactory::Create(CppOptions);
}

void OtlpHttpSpanExporterProxy::getDefaultOptionValues(libmexclass::proxy::method::Context& context) {
    otlp_exporter::OtlpHttpExporterOptions options;
    matlab::data::ArrayFactory factory;
    auto endpoint_mda = factory.createScalar(options.url);
    std::string dataformat, json_bytes_mapping;
    // dataformat
    if (options.content_type == otlp_exporter::HttpRequestContentType::kJson) {
        dataformat = "JSON";
    } else {
	dataformat = "binary";
    }
    // json_bytes_mapping
    if (options.json_bytes_mapping == otlp_exporter::JsonBytesMappingKind::kHex) {
        json_bytes_mapping = "hex";
    } else if (options.json_bytes_mapping == otlp_exporter::JsonBytesMappingKind::kHexId) {
        json_bytes_mapping = "hexId";
    } else {   // kBase64
        json_bytes_mapping = "base64";
    }
    auto dataformat_mda = factory.createScalar(dataformat);
    auto json_bytes_mapping_mda = factory.createScalar(json_bytes_mapping);
    auto timeout_millis = std::chrono::duration_cast<std::chrono::milliseconds>(options.timeout);
    auto timeout_mda = factory.createScalar(static_cast<double>(timeout_millis.count()));
    context.outputs[0] = endpoint_mda;
    context.outputs[1] = dataformat_mda;
    context.outputs[2] = json_bytes_mapping_mda;
    context.outputs[3] = timeout_mda;
}
} // namespace libmexclass::opentelemetry
