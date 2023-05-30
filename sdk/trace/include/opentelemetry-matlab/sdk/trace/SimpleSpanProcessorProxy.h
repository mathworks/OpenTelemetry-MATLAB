// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/trace/SpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/SpanExporterProxy.h"

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/sdk/trace/simple_processor_factory.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class SimpleSpanProcessorProxy : public SpanProcessorProxy {
  public:
    SimpleSpanProcessorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) 
	    : SpanProcessorProxy(constructor_arguments) {}
	    //: SpanProcessorProxy(constructor_arguments[0]) {}

    std::unique_ptr<trace_sdk::SpanProcessor> getInstance() override {
        return trace_sdk::SimpleSpanProcessorFactory::Create(std::move(SpanExporter->getInstance()));
    }
};
} // namespace libmexclass::opentelemetry
