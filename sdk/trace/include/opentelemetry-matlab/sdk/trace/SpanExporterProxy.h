// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/sdk/trace/exporter.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class SpanExporterProxy : public libmexclass::proxy::Proxy {
  public:
    virtual std::unique_ptr<trace_sdk::SpanExporter> getInstance() = 0;
};
} // namespace libmexclass::opentelemetry
