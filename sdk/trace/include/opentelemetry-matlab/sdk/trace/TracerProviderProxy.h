// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"

#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/sdk/trace/batch_span_processor_factory.h"
#include "opentelemetry/sdk/resource/resource.h"
#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"
#include "opentelemetry/exporters/ostream/span_exporter_factory.h"
#include "opentelemetry/trace/tracer_provider.h"

#define OTEL_MATLAB_VERSION "0.1"

namespace trace_api = opentelemetry::trace;
namespace trace_sdk = opentelemetry::sdk::trace;
namespace trace_exporter = opentelemetry::exporter::otlp;
//namespace trace_exporter = opentelemetry::exporter::trace;
namespace nostd = opentelemetry::nostd;
namespace resource = opentelemetry::sdk::resource;

namespace libmexclass::opentelemetry::sdk {
class TracerProviderProxy : public libmexclass::opentelemetry::TracerProviderProxy {
  public:
    TracerProviderProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments)
    {
	//auto exporter = trace_exporter::OStreamSpanExporterFactory::Create();
        auto exporter = trace_exporter::OtlpHttpExporterFactory::Create();
	trace_sdk::BatchSpanProcessorOptions options;
	auto processor = trace_sdk::BatchSpanProcessorFactory::Create(
            std::move(exporter), options);
	CppTracerProvider = nostd::shared_ptr<trace_api::TracerProvider>(
	    std::move(trace_sdk::TracerProviderFactory::Create(std::move(processor),
            resource::Resource::Create({ {"telemetry.sdk.language", "MATLAB"}, {"telemetry.sdk.version", OTEL_MATLAB_VERSION} }))));
    }
};
} // namespace libmexclass::opentelemetry
