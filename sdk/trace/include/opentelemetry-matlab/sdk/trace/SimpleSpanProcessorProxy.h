// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/simple_processor_factory.h"
#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"

namespace trace_sdk = opentelemetry::sdk::trace;
namespace trace_exporter = opentelemetry::exporter::otlp;

namespace libmexclass::opentelemetry::sdk {
class SimpleSpanProcessorProxy : public libmexclass::proxy::Proxy {
  public:
    SimpleSpanProcessorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) {}

    std::unique_ptr<trace_sdk::SpanProcessor> getInstance() {
        auto exporter = trace_exporter::OtlpHttpExporterFactory::Create();
        return trace_sdk::SimpleSpanProcessorFactory::Create(std::move(exporter));
    }
};
} // namespace libmexclass::opentelemetry
