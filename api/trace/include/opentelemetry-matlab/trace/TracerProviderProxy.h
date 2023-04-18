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
    // this constructor should only be used by getTracerProvider
    TracerProviderProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments)
    {
        // get the global instance instead of creating a new instance
	CppTracerProvider = trace_api::Provider::GetTracerProvider();
        registerMethods(); 
    }

    // default constructor should only be called by SDK TracerProvider constructor
    TracerProviderProxy() {
        registerMethods();
    }

    void getTracer(libmexclass::proxy::method::Context& context);

    void setTracerProvider(libmexclass::proxy::method::Context& context);

  private:
    void registerMethods() {
        REGISTER_METHOD(TracerProviderProxy, getTracer);
        REGISTER_METHOD(TracerProviderProxy, setTracerProvider);
    }

  protected:
    nostd::shared_ptr<trace_api::TracerProvider> CppTracerProvider;
};
} // namespace libmexclass::opentelemetry
