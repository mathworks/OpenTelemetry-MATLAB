// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SpanExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/sdk/trace/processor.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class SpanProcessorProxy : public libmexclass::proxy::Proxy {
  public:
    virtual std::unique_ptr<trace_sdk::SpanProcessor> getInstance() = 0;

  protected:
    SpanProcessorProxy(std::shared_ptr<SpanExporterProxy> exporter) : SpanExporter(exporter) {}

    std::shared_ptr<SpanExporterProxy> SpanExporter;
};
} // namespace libmexclass::opentelemetry
