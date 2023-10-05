// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/MeterProviderProxy.h"
#include "opentelemetry-matlab/metrics/MeterProxy.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/metrics/provider.h"

#include "MatlabDataArray.hpp"
namespace libmexclass::opentelemetry {
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

void MeterProviderProxy::setMeterProvider(libmexclass::proxy::method::Context& context) {
   metrics_api::Provider::SetMeterProvider(CppMeterProvider);
}

} // namespace libmexclass::opentelemetry
