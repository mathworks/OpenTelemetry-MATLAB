// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/trace/TracerProxy.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/trace/provider.h"

#include "MatlabDataArray.hpp"
namespace libmexclass::opentelemetry {
void TracerProviderProxy::getTracer(libmexclass::proxy::method::Context& context) {
   // Always assumes 3 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray version_mda = context.inputs[1];
   std::string version = static_cast<std::string>(version_mda[0]);
   matlab::data::StringArray schema_mda = context.inputs[2];
   std::string schema = static_cast<std::string>(schema_mda[0]); 
	
   auto tr = CppTracerProvider->GetTracer(name, version, schema);

   // instantiate a TracerProxy instance
   TracerProxy* newproxy = new TracerProxy(tr);
   auto trproxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(trproxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}

void TracerProviderProxy::setTracerProvider(libmexclass::proxy::method::Context& context) {
   trace_api::Provider::SetTracerProvider(CppTracerProvider);
}

} // namespace libmexclass::opentelemetry
