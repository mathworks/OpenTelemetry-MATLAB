// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/logs/LogRecordProcessorProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/logs/processor.h"
#include "opentelemetry/sdk/logs/batch_log_record_processor_options.h"

namespace logs_sdk = opentelemetry::sdk::logs;

namespace libmexclass::opentelemetry::sdk {
class BatchLogRecordProcessorProxy : public LogRecordProcessorProxy {
  public:
    BatchLogRecordProcessorProxy(std::shared_ptr<LogRecordExporterProxy> exporter);

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<logs_sdk::LogRecordProcessor> getInstance() override;

    void setMaximumQueueSize(libmexclass::proxy::method::Context& context);

    void setScheduledDelay(libmexclass::proxy::method::Context& context);

    void setMaximumExportBatchSize(libmexclass::proxy::method::Context& context);

  private:
    logs_sdk::BatchLogRecordProcessorOptions CppOptions;
};
} // namespace libmexclass::opentelemetry
