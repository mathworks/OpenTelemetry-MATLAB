// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/logs/BatchLogRecordProcessorProxy.h"
#include "opentelemetry-matlab/sdk/logs/LogRecordExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/logs/batch_log_record_processor_factory.h"

namespace libmexclass::opentelemetry::sdk {
BatchLogRecordProcessorProxy::BatchLogRecordProcessorProxy(std::shared_ptr<LogRecordExporterProxy> exporter)
	: LogRecordProcessorProxy(exporter) {
    REGISTER_METHOD(BatchLogRecordProcessorProxy, setMaximumQueueSize);
    REGISTER_METHOD(BatchLogRecordProcessorProxy, setScheduledDelay);
    REGISTER_METHOD(BatchLogRecordProcessorProxy, setMaximumExportBatchSize);
}

libmexclass::proxy::MakeResult BatchLogRecordProcessorProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
    libmexclass::proxy::ID exporterid = exporterid_mda[0];	
    std::shared_ptr<LogRecordExporterProxy> exporter = std::static_pointer_cast<LogRecordExporterProxy>(
        libmexclass::proxy::ProxyManager::getProxy(exporterid));
    return std::make_shared<BatchLogRecordProcessorProxy>(exporter);
}

std::unique_ptr<logs_sdk::LogRecordProcessor> BatchLogRecordProcessorProxy::getInstance() {
    return logs_sdk::BatchLogRecordProcessorFactory::Create(std::move(LogRecordExporter->getInstance()), CppOptions);
}

void BatchLogRecordProcessorProxy::setMaximumQueueSize(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> qsize_mda = context.inputs[0];
    double qsize = qsize_mda[0];
    if (qsize > 0) {
        CppOptions.max_queue_size = static_cast<size_t>(qsize);
    }
}

void BatchLogRecordProcessorProxy::setScheduledDelay(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> delay_mda = context.inputs[0];
    double delay = delay_mda[0];
    if (delay > 0) {
        CppOptions.schedule_delay_millis = std::chrono::milliseconds(static_cast<int64_t>(delay));
    }
}

void BatchLogRecordProcessorProxy::setMaximumExportBatchSize(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> batchsize_mda = context.inputs[0];
    double batchsize = batchsize_mda[0];
    if (batchsize > 0) {
        CppOptions.max_export_batch_size = static_cast<size_t>(batchsize);
    }
}
} // namespace libmexclass::opentelemetry
