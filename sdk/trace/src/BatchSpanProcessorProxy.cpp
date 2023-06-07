// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/BatchSpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/SpanExporterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/batch_span_processor_factory.h"

namespace libmexclass::opentelemetry::sdk {
BatchSpanProcessorProxy::BatchSpanProcessorProxy(std::shared_ptr<SpanExporterProxy> exporter, 
		double qsize, double delay, double batchsize)
	: SpanProcessorProxy(exporter) {

    if (qsize > 0) {
        CppOptions.max_queue_size = static_cast<size_t>(qsize);
    } 
    if (delay > 0) {
        CppOptions.schedule_delay_millis = std::chrono::milliseconds(static_cast<int64_t>(delay));
    }
    if (batchsize > 0) {
        CppOptions.max_export_batch_size = static_cast<size_t>(batchsize);
    }
    REGISTER_METHOD(BatchSpanProcessorProxy, getDefaultOptionValues);
}

libmexclass::proxy::MakeResult BatchSpanProcessorProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
    libmexclass::proxy::ID exporterid = exporterid_mda[0];
    std::shared_ptr<SpanExporterProxy> exporter = std::static_pointer_cast<SpanExporterProxy>(
        libmexclass::proxy::ProxyManager::getProxy(exporterid));
    matlab::data::TypedArray<double> qsize_mda = constructor_arguments[1];
    double qsize = qsize_mda[0];
    matlab::data::TypedArray<double> delay_mda = constructor_arguments[2];
    double delay = delay_mda[0];
    matlab::data::TypedArray<double> batchsize_mda = constructor_arguments[3];
    double batchsize = batchsize_mda[0];
    
    return std::make_shared<BatchSpanProcessorProxy>(exporter, qsize, delay, batchsize);
}

std::unique_ptr<trace_sdk::SpanProcessor> BatchSpanProcessorProxy::getInstance() {
    return trace_sdk::BatchSpanProcessorFactory::Create(std::move(SpanExporter->getInstance()), CppOptions);
}

void BatchSpanProcessorProxy::getDefaultOptionValues(libmexclass::proxy::method::Context& context) {
    trace_sdk::BatchSpanProcessorOptions options;
    matlab::data::ArrayFactory factory;
    auto qsize_mda = factory.createScalar<double>(static_cast<double>(
			    options.max_queue_size));
    auto delay_mda = factory.createScalar<double>(static_cast<double>(
			    options.schedule_delay_millis.count()));
    auto batchsize_mda = factory.createScalar<double>(static_cast<double>(
			    options.max_export_batch_size));
    context.outputs[0] = qsize_mda;
    context.outputs[1] = delay_mda;
    context.outputs[2] = batchsize_mda;
}
} // namespace libmexclass::opentelemetry
