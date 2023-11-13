// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SpanProcessorProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/processor.h"
#include "opentelemetry/sdk/trace/batch_span_processor_options.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class BatchSpanProcessorProxy : public SpanProcessorProxy {
  public:
    BatchSpanProcessorProxy(std::shared_ptr<SpanExporterProxy> exporter);

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<trace_sdk::SpanProcessor> getInstance() override;

    void setMaximumQueueSize(libmexclass::proxy::method::Context& context);

    void setScheduledDelay(libmexclass::proxy::method::Context& context);

    void setMaximumExportBatchSize(libmexclass::proxy::method::Context& context);

  private:
    trace_sdk::BatchSpanProcessorOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
