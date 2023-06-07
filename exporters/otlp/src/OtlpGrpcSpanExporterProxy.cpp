// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/exporters/otlp/OtlpGrpcSpanExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/exporters/otlp/otlp_grpc_exporter_factory.h"

namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
libmexclass::proxy::MakeResult OtlpGrpcSpanExporterProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::StringArray endpoint_mda = constructor_arguments[0];
    std::string endpoint = static_cast<std::string>(endpoint_mda[0]);
    matlab::data::TypedArray<bool> use_ssl_mda = constructor_arguments[1];
    bool use_ssl = use_ssl_mda[0];
    matlab::data::StringArray certpath_mda = constructor_arguments[2];
    std::string certpath = static_cast<std::string>(certpath_mda[0]);
    matlab::data::StringArray certstring_mda = constructor_arguments[3];
    std::string certstring = static_cast<std::string>(certstring_mda[0]);
    matlab::data::TypedArray<double> timeout_mda = constructor_arguments[4];
    double timeout = timeout_mda[0];
    matlab::data::Array header_mda = constructor_arguments[5];
    size_t nheaders = header_mda.getNumberOfElements();
    matlab::data::StringArray headernames_mda = constructor_arguments[5];
    matlab::data::StringArray headervalues_mda = constructor_arguments[6];

    otlp_exporter::OtlpGrpcExporterOptions options;
    if (!endpoint.empty()) {
        options.endpoint = endpoint;
    } 
    // use_ssl
    options.use_ssl_credentials = use_ssl;
    if (!certpath.empty()) {
        options.ssl_credentials_cacert_path = certpath;
    } 
    if (!certstring.empty()) {
        options.ssl_credentials_cacert_as_string = certstring;
    } 
    // timeout
    if (timeout >= 0) {
        options.timeout = std::chrono::milliseconds(static_cast<int64_t>(timeout));
    }
    // http headers
    for (size_t i = 0; i < nheaders; ++i) {
        options.metadata.insert(std::pair{static_cast<std::string>(headernames_mda[i]),
				static_cast<std::string>(headervalues_mda[i])});
    }
    return std::make_shared<OtlpGrpcSpanExporterProxy>(options);
}

std::unique_ptr<trace_sdk::SpanExporter> OtlpGrpcSpanExporterProxy::getInstance() {
    return otlp_exporter::OtlpGrpcExporterFactory::Create(CppOptions);
}

void OtlpGrpcSpanExporterProxy::getDefaultOptionValues(libmexclass::proxy::method::Context& context) {
    otlp_exporter::OtlpGrpcExporterOptions options;
    matlab::data::ArrayFactory factory;
    auto endpoint_mda = factory.createScalar(options.endpoint);
    auto certpath_mda = factory.createScalar(options.ssl_credentials_cacert_path);
    auto certstring_mda = factory.createScalar(options.ssl_credentials_cacert_as_string);
    auto timeout_millis = std::chrono::duration_cast<std::chrono::milliseconds>(options.timeout);
    auto timeout_mda = factory.createScalar(static_cast<double>(timeout_millis.count()));
    context.outputs[0] = endpoint_mda;
    context.outputs[1] = certpath_mda;
    context.outputs[2] = certstring_mda;
    context.outputs[3] = timeout_mda;
}
} // namespace libmexclass::opentelemetry
