// Copyright 2025 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/trace/tracer_provider.h"
#include "opentelemetry/trace/provider.h"
#include "opentelemetry/trace/noop.h"

namespace trace_api = opentelemetry::trace;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class NoOpTracerProviderProxy : public libmexclass::proxy::Proxy {
  public:
    NoOpTracerProviderProxy(nostd::shared_ptr<trace_api::TracerProvider> tp) : CppTracerProvider(tp) {
        // set as global TracerProvider instance
        trace_api::Provider::SetTracerProvider(CppTracerProvider);
    } 

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<NoOpTracerProviderProxy>(nostd::shared_ptr<trace_api::TracerProvider>(new trace_api::NoopTracerProvider()));
    }

  protected:
    nostd::shared_ptr<trace_api::TracerProvider> CppTracerProvider;
};
} // namespace libmexclass::opentelemetry
