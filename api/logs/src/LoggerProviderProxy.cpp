// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/logs/LoggerProviderProxy.h"
#include "opentelemetry-matlab/logs/LoggerProxy.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/logs/provider.h"

#include "MatlabDataArray.hpp"
namespace libmexclass::opentelemetry {
void LoggerProviderProxy::getLogger(libmexclass::proxy::method::Context& context) {
   // Always assumes 3 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray version_mda = context.inputs[1];
   std::string version = static_cast<std::string>(version_mda[0]);
   matlab::data::StringArray schema_mda = context.inputs[2];
   std::string schema = static_cast<std::string>(schema_mda[0]); 
	
   auto lg = CppLoggerProvider->GetLogger(name, version, schema);

   // instantiate a LoggerProxy instance
   LoggerProxy* newproxy = new LoggerProxy(lg);
   auto lgproxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(lgproxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}

void LoggerProviderProxy::setLoggerProvider(libmexclass::proxy::method::Context& context) {
   logs_api::Provider::SetLoggerProvider(CppLoggerProvider);
}

} // namespace libmexclass::opentelemetry
