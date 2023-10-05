// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"
#include "opentelemetry-matlab/sdk/metrics/PeriodicExportingMetricReaderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include <chrono>

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult MeterProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    
    libmexclass::proxy::MakeResult out;

    matlab::data::TypedArray<uint64_t> readerid_mda = constructor_arguments[0];
    libmexclass::proxy::ID readerid = readerid_mda[0];
    
    auto reader = std::static_pointer_cast<PeriodicExportingMetricReaderProxy>(
	        libmexclass::proxy::ProxyManager::getProxy(readerid))->getInstance();
    auto p = metrics_sdk::MeterProviderFactory::Create();
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



void MeterProviderProxy::addMetricReader(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> readerid_mda = context.inputs[0];
    libmexclass::proxy::ID readerid = readerid_mda[0];

    static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).AddMetricReader(
		    std::static_pointer_cast<PeriodicExportingMetricReaderProxy>(
			    libmexclass::proxy::ProxyManager::getProxy(readerid))->getInstance());
   return;
}




} // namespace libmexclass::opentelemetry
