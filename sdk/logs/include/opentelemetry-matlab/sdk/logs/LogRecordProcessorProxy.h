// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/logs/LogRecordExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/logs/processor.h"

namespace logs_sdk = opentelemetry::sdk::logs;

namespace libmexclass::opentelemetry::sdk {
class LogRecordProcessorProxy : public libmexclass::proxy::Proxy {
  public:
    virtual std::unique_ptr<logs_sdk::LogRecordProcessor> getInstance() = 0;

  protected:
    LogRecordProcessorProxy(std::shared_ptr<LogRecordExporterProxy> exporter) : LogRecordExporter(exporter) {}

    std::shared_ptr<LogRecordExporterProxy> LogRecordExporter;
};
} // namespace libmexclass::opentelemetry
