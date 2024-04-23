// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/sdk/logs/exporter.h"

namespace logs_sdk = opentelemetry::sdk::logs;

namespace libmexclass::opentelemetry::sdk {
class LogRecordExporterProxy : public libmexclass::proxy::Proxy {
  public:
    virtual std::unique_ptr<logs_sdk::LogRecordExporter> getInstance() = 0;
};
} // namespace libmexclass::opentelemetry
