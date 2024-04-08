// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/logs/LogRecordProcessorProxy.h"
#include "opentelemetry-matlab/sdk/logs/LogRecordExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/sdk/logs/simple_log_record_processor_factory.h"

namespace logs_sdk = opentelemetry::sdk::logs;

namespace libmexclass::opentelemetry::sdk {
class SimpleLogRecordProcessorProxy : public LogRecordProcessorProxy {
  public:
    SimpleLogRecordProcessorProxy(std::shared_ptr<LogRecordExporterProxy> exporter) 
	    : LogRecordProcessorProxy(exporter) {}

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    std::unique_ptr<logs_sdk::LogRecordProcessor> getInstance() override {
        return logs_sdk::SimpleLogRecordProcessorFactory::Create(std::move(LogRecordExporter->getInstance()));
    }
};
} // namespace libmexclass::opentelemetry
