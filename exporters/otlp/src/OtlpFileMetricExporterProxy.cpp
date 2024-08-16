// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/exporters/otlp/OtlpFileMetricExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/exporters/otlp/otlp_file_metric_exporter_factory.h"
#include "opentelemetry/exporters/otlp/otlp_file_client_options.h"

namespace otlp_exporter = opentelemetry::exporter::otlp;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry::exporters {
libmexclass::proxy::MakeResult OtlpFileMetricExporterProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    otlp_exporter::OtlpFileMetricExporterOptions options;
    return std::make_shared<OtlpFileMetricExporterProxy>(options);
}

std::unique_ptr<metric_sdk::PushMetricExporter> OtlpFileMetricExporterProxy::getInstance() {
    return otlp_exporter::OtlpFileMetricExporterFactory::Create(CppOptions);
}

void OtlpFileMetricExporterProxy::setFileName(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray filename_mda = context.inputs[0];
    std::string filename = static_cast<std::string>(filename_mda[0]);
    auto options = nostd::get<otlp_exporter::OtlpFileClientFileSystemOptions>(CppOptions.backend_options);
    options.file_pattern = filename;
    CppOptions.backend_options = options;
}

void OtlpFileMetricExporterProxy::setAliasName(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray aliasname_mda = context.inputs[0];
    std::string aliasname = static_cast<std::string>(aliasname_mda[0]);
    auto options = nostd::get<otlp_exporter::OtlpFileClientFileSystemOptions>(CppOptions.backend_options);
    options.alias_pattern = aliasname;
    CppOptions.backend_options = options;
}

void OtlpFileMetricExporterProxy::setFlushInterval(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> flushinterval_mda = context.inputs[0];
    double flushinterval = flushinterval_mda[0];
    auto options = nostd::get<otlp_exporter::OtlpFileClientFileSystemOptions>(CppOptions.backend_options);
    options.flush_interval = std::chrono::milliseconds(static_cast<int64_t>(flushinterval));
    CppOptions.backend_options = options;
}

void OtlpFileMetricExporterProxy::setFlushRecordCount(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> flushrecordcount_mda = context.inputs[0];
    double flushrecordcount = flushrecordcount_mda[0];
    auto options = nostd::get<otlp_exporter::OtlpFileClientFileSystemOptions>(CppOptions.backend_options);
    options.flush_count = static_cast<std::size_t>(flushrecordcount);
    CppOptions.backend_options = options;
}

void OtlpFileMetricExporterProxy::setMaxFileSize(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> maxfilesize_mda = context.inputs[0];
    double maxfilesize = maxfilesize_mda[0];
    auto options = nostd::get<otlp_exporter::OtlpFileClientFileSystemOptions>(CppOptions.backend_options);
    options.file_size = static_cast<std::size_t>(maxfilesize);
    CppOptions.backend_options = options;
}

void OtlpFileMetricExporterProxy::setMaxFileCount(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> maxfilecount_mda = context.inputs[0];
    double maxfilecount = maxfilecount_mda[0];
    auto options = nostd::get<otlp_exporter::OtlpFileClientFileSystemOptions>(CppOptions.backend_options);
    options.rotate_size = static_cast<std::size_t>(maxfilecount);
    CppOptions.backend_options = options;
}

} // namespace libmexclass::opentelemetry
