// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/BatchSpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/SpanExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/batch_span_processor_factory.h"

namespace libmexclass::opentelemetry::sdk {
BatchSpanProcessorProxy::BatchSpanProcessorProxy(std::shared_ptr<SpanExporterProxy> exporter)
	: SpanProcessorProxy(exporter) {
    REGISTER_METHOD(BatchSpanProcessorProxy, setMaximumQueueSize);
    REGISTER_METHOD(BatchSpanProcessorProxy, setScheduledDelay);
    REGISTER_METHOD(BatchSpanProcessorProxy, setMaximumExportBatchSize);
}

libmexclass::proxy::MakeResult BatchSpanProcessorProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
    libmexclass::proxy::ID exporterid = exporterid_mda[0];	
    std::shared_ptr<SpanExporterProxy> exporter = std::static_pointer_cast<SpanExporterProxy>(
        libmexclass::proxy::ProxyManager::getProxy(exporterid));
    return std::make_shared<BatchSpanProcessorProxy>(exporter);
}

std::unique_ptr<trace_sdk::SpanProcessor> BatchSpanProcessorProxy::getInstance() {
    return trace_sdk::BatchSpanProcessorFactory::Create(std::move(SpanExporter->getInstance()), CppOptions);
}

void BatchSpanProcessorProxy::setMaximumQueueSize(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> qsize_mda = context.inputs[0];
    double qsize = qsize_mda[0];
    if (qsize > 0) {
        CppOptions.max_queue_size = static_cast<size_t>(qsize);
    }
}

void BatchSpanProcessorProxy::setScheduledDelay(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> delay_mda = context.inputs[0];
    double delay = delay_mda[0];
    if (delay > 0) {
        CppOptions.schedule_delay_millis = std::chrono::milliseconds(static_cast<int64_t>(delay));
    }
}

void BatchSpanProcessorProxy::setMaximumExportBatchSize(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> batchsize_mda = context.inputs[0];
    double batchsize = batchsize_mda[0];
    if (batchsize > 0) {
        CppOptions.max_export_batch_size = static_cast<size_t>(batchsize);
    }
}
} // namespace libmexclass::opentelemetry
