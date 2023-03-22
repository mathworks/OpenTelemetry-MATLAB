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
    SpanProcessorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
        libmexclass::proxy::ID exporterid = exporterid_mda[0];
        SpanExporter = std::static_pointer_cast<SpanExporterProxy>(
			libmexclass::proxy::ProxyManager::getProxy(exporterid));
    }

    std::shared_ptr<SpanExporterProxy> SpanExporter;
};
} // namespace libmexclass::opentelemetry
