// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include <chrono>
#include <memory>
#include <thread>

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult MeterProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    
    libmexclass::proxy::MakeResult out;
  
    auto exporter = otlpexporter::OtlpHttpMetricExporterFactory::Create();
    // Initialize and set the periodic metrics reader
    metrics_sdk::PeriodicExportingMetricReaderOptions options;
    options.export_interval_millis = std::chrono::milliseconds(1000);
    options.export_timeout_millis  = std::chrono::milliseconds(500);
    auto reader = metrics_sdk::PeriodicExportingMetricReaderFactory::Create(std::move(exporter), options);

    auto p = metrics_sdk::MeterProviderFactory::Create();
    // auto p = nostd::shared_ptr<metrics_api::MeterProvider>(std::move(metrics_sdk::MeterProviderFactory::Create()));
    auto *p_sdk = static_cast<metrics_sdk::MeterProvider *>(p.get());
    p_sdk->AddMetricReader(std::move(reader));
  
    auto p_out = nostd::shared_ptr<metrics_api::MeterProvider>(std::move(p));

    out = std::make_shared<MeterProviderProxy>(p_out);
    
    return out;
}

void MeterProviderProxy::getMeter(libmexclass::proxy::method::Context& context) {
   // Always assumes 3 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray version_mda = context.inputs[1];
   std::string version = static_cast<std::string>(version_mda[0]);
   matlab::data::StringArray schema_mda = context.inputs[2];
   std::string schema = static_cast<std::string>(schema_mda[0]); 
	
   auto mt = CppMeterProvider->GetMeter(name, version, schema);

   // instantiate a MeterProxy instance
   MeterProxy* newproxy = new MeterProxy(mt);
   auto mtproxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(mtproxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}


} // namespace libmexclass::opentelemetry
