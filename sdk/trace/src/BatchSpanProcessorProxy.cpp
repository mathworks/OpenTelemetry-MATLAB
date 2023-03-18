// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/BatchSpanProcessorProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"
#include "opentelemetry/sdk/trace/batch_span_processor_factory.h"
#include "opentelemetry/sdk/trace/batch_span_processor_options.h"

namespace trace_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::sdk {
BatchSpanProcessorProxy::BatchSpanProcessorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<double> qsize_mda = constructor_arguments[0];
    double qsize = qsize_mda[0];
    matlab::data::TypedArray<double> delay_mda = constructor_arguments[1];
    double delay = delay_mda[0];
    matlab::data::TypedArray<double> batchsize_mda = constructor_arguments[2];
    double batchsize = batchsize_mda[0];

    if (qsize > 0) {
        CppOptions.max_queue_size = static_cast<size_t>(qsize);
    } 
    if (delay > 0) {
        CppOptions.schedule_delay_millis = std::chrono::milliseconds(static_cast<int64_t>(delay));
    }
    if (batchsize > 0) {
        CppOptions.max_export_batch_size = static_cast<size_t>(batchsize);
    }
}

std::unique_ptr<trace_sdk::SpanProcessor> BatchSpanProcessorProxy::getInstance() {
    auto exporter = trace_exporter::OtlpHttpExporterFactory::Create();
    return trace_sdk::BatchSpanProcessorFactory::Create(std::move(exporter, CppOptions));
}

} // namespace libmexclass::opentelemetry
