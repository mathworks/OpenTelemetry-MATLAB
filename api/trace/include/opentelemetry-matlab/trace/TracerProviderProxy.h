// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/sdk/trace/batch_span_processor_factory.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"
#include "opentelemetry/exporters/ostream/span_exporter_factory.h"
#include "opentelemetry/trace/tracer_provider.h"
#include "opentelemetry/trace/provider.h"
#include "opentelemetry/trace/noop.h"

#define OTEL_MATLAB_VERSION "0.1.0"

namespace trace_api = opentelemetry::trace;
namespace trace_sdk = opentelemetry::sdk::trace;
namespace trace_exporter = opentelemetry::exporter::otlp;
//namespace trace_exporter = opentelemetry::exporter::trace;
namespace nostd = opentelemetry::nostd;
namespace resource = opentelemetry::sdk::resource;

namespace libmexclass::opentelemetry {
class TracerProviderProxy : public libmexclass::proxy::Proxy {
  public:
    TracerProviderProxy(nostd::shared_ptr<trace_api::TracerProvider> tp) : CppTracerProvider(tp) {
        REGISTER_METHOD(TracerProviderProxy, getTracer);
        REGISTER_METHOD(TracerProviderProxy, setTracerProvider);
        REGISTER_METHOD(TracerProviderProxy, postShutdown);
    }

    // Static make method should only be used by getTracerProvider. It gets the global instance 
    // instead of creating a new instance
    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<TracerProviderProxy>(trace_api::Provider::GetTracerProvider());
    }

    void getTracer(libmexclass::proxy::method::Context& context);

    void setTracerProvider(libmexclass::proxy::method::Context& context);

    nostd::shared_ptr<trace_api::TracerProvider> getInstance() {
        return CppTracerProvider;
    }

    void postShutdown(libmexclass::proxy::method::Context& context) {
	// Replace tracer provider with a no-op instance. Subsequent tracers and spans won't be recorded
	nostd::shared_ptr<trace_api::TracerProvider> noop(new trace_api::NoopTracerProvider);
        CppTracerProvider.swap(noop);
    }

  protected:
    nostd::shared_ptr<trace_api::TracerProvider> CppTracerProvider;
};
} // namespace libmexclass::opentelemetry
