// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/MeterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "MatlabDataArray.hpp"

#include <chrono>

namespace libmexclass::opentelemetry {
void MeterProxy::createCounter(libmexclass::proxy::method::Context& context) {
    // Always assumes 3 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray description_mda = context.inputs[1];
   std::string description= static_cast<std::string>(description_mda[0]);
   matlab::data::StringArray unit_mda = context.inputs[2];
   std::string unit = static_cast<std::string>(unit_mda[0]); 
	
   nostd::shared_ptr<metrics_api::Counter<double> > ct = std::move(CppMeter->CreateDoubleCounter(name, description, unit));

   // instantiate a CounterProxy instance
   CounterProxy* newproxy = new CounterProxy(ct);
   auto proxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(proxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}


void MeterProxy::createUpDownCounter(libmexclass::proxy::method::Context& context) {
    // Always assumes 3 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray description_mda = context.inputs[1];
   std::string description= static_cast<std::string>(description_mda[0]);
   matlab::data::StringArray unit_mda = context.inputs[2];
   std::string unit = static_cast<std::string>(unit_mda[0]); 
	
   nostd::shared_ptr<metrics_api::UpDownCounter<double> > ct = std::move(CppMeter->CreateDoubleUpDownCounter
(name, description, unit));

   // instantiate a UpDownCounterProxy instance
   UpDownCounterProxy* newproxy = new UpDownCounterProxy(ct);
   auto proxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(proxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}


void MeterProxy::createHistogram(libmexclass::proxy::method::Context& context) {
    // Always assumes 3 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray description_mda = context.inputs[1];
   std::string description= static_cast<std::string>(description_mda[0]);
   matlab::data::StringArray unit_mda = context.inputs[2];
   std::string unit = static_cast<std::string>(unit_mda[0]); 
	
   nostd::shared_ptr<metrics_api::Histogram<double> > hist = std::move(CppMeter->CreateDoubleHistogram(name, description, unit));

   // instantiate a HistogramProxy instance
   HistogramProxy* newproxy = new HistogramProxy(hist);
   auto proxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(proxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}


} // namespace libmexclass::opentelemetry
