// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include <chrono>

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult MeterProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    
    libmexclass::proxy::MakeResult out;
  
    auto exporter = otlpexporter::OtlpHttpMetricExporterFactory::Create();
    // Initialize and set the periodic metrics reader
    metrics_sdk::PeriodicExportingMetricReaderOptions options;
    auto reader = metrics_sdk::PeriodicExportingMetricReaderFactory::Create(std::move(exporter), options);

    auto p = metrics_sdk::MeterProviderFactory::Create();
    auto *p_sdk = static_cast<metrics_sdk::MeterProvider *>(p.get());
    p_sdk->AddMetricReader(std::move(reader));
  
    auto p_out = nostd::shared_ptr<metrics_api::MeterProvider>(std::move(p));
    out = std::make_shared<MeterProviderProxy>(p_out);
    
    return out;
}

} // namespace libmexclass::opentelemetry
