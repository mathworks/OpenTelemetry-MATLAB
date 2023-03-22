// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/exporters/otlp/OtlpHttpSpanExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"

namespace otlp_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::exporters {
OtlpHttpSpanExporterProxy::OtlpHttpSpanExporterProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::StringArray endpoint_mda = constructor_arguments[0];
    std::string endpoint = static_cast<std::string>(endpoint_mda[0]);
    matlab::data::TypedArray<double> timeout_mda = constructor_arguments[1];
    double timeout = timeout_mda[0];

    if (!endpoint.empty()) {
        CppOptions.url = endpoint;
    } 
    if (timeout >= 0) {
        CppOptions.timeout = std::chrono::milliseconds(static_cast<int64_t>(timeout));
    }
    REGISTER_METHOD(OtlpHttpSpanExporterProxy, getDefaultOptionValues);
}

std::unique_ptr<trace_sdk::SpanExporter> OtlpHttpSpanExporterProxy::getInstance() {
    return otlp_exporter::OtlpHttpExporterFactory::Create(CppOptions);
}

void OtlpHttpSpanExporterProxy::getDefaultOptionValues(libmexclass::proxy::method::Context& context) {
    otlp_exporter::OtlpHttpExporterOptions options;
    matlab::data::ArrayFactory factory;
    auto endpoint_mda = factory.createScalar(options.url);
    auto timeout_millis = std::chrono::duration_cast<std::chrono::milliseconds>(options.timeout);
    auto timeout_mda = factory.createScalar(static_cast<double>(timeout_millis.count()));
    context.outputs[0] = endpoint_mda;
    context.outputs[1] = timeout_mda;
}
} // namespace libmexclass::opentelemetry
