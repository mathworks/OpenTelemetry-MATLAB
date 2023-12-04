// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/MeterProxy.h"
#include "opentelemetry-matlab/metrics/MeasurementFetcher.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "MatlabDataArray.hpp"

#include <chrono>

namespace libmexclass::opentelemetry {

void MeterProxy::createSynchronous(libmexclass::proxy::method::Context& context, SynchronousInstrumentType type) {
    // Always assumes 3 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray description_mda = context.inputs[1];
   std::string description= static_cast<std::string>(description_mda[0]);
   matlab::data::StringArray unit_mda = context.inputs[2];
   std::string unit = static_cast<std::string>(unit_mda[0]); 
	
   SynchronousInstrumentProxyFactory proxyfactory(CppMeter);
   auto proxy = proxyfactory.create(type, name, description, unit);
    
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(proxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}

void MeterProxy::createCounter(libmexclass::proxy::method::Context& context) {
   createSynchronous(context, SynchronousInstrumentType::Counter);
}


void MeterProxy::createUpDownCounter(libmexclass::proxy::method::Context& context) {
   createSynchronous(context, SynchronousInstrumentType::UpDownCounter);
}


void MeterProxy::createHistogram(libmexclass::proxy::method::Context& context) {
   createSynchronous(context, SynchronousInstrumentType::Histogram);
}

void MeterProxy::createAsynchronous(libmexclass::proxy::method::Context& context, AsynchronousInstrumentType type) {
    // Always assumes 4 inputs
   matlab::data::StringArray name_mda = context.inputs[0];
   std::string name = static_cast<std::string>(name_mda[0]);
   matlab::data::StringArray description_mda = context.inputs[1];
   std::string description= static_cast<std::string>(description_mda[0]);
   matlab::data::StringArray unit_mda = context.inputs[2];
   std::string unit = static_cast<std::string>(unit_mda[0]); 
   matlab::data::StringArray callback_mda = context.inputs[3];
   std::string callback = static_cast<std::string>(callback_mda[0]); 
	
   // initialize MATLAB mex engine the first time an asynchronous instrument is created 
   if (MeasurementFetcher::mlptr == nullptr) {
      MeasurementFetcher::mlptr = static_cast<std::shared_ptr<matlab::engine::MATLABEngine> >(context.matlab); 
   }

   AsynchronousInstrumentProxyFactory proxyfactory(CppMeter);
   auto proxy = proxyfactory.create(type, callback, name, description, unit);
   
   // obtain a proxy ID
   libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(proxy);

   // return the ID
   matlab::data::ArrayFactory factory;
   auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
   context.outputs[0] = proxyid_mda;
}

void MeterProxy::createObservableCounter(libmexclass::proxy::method::Context& context) {
   createAsynchronous(context, AsynchronousInstrumentType::ObservableCounter);
}

void MeterProxy::createObservableUpDownCounter(libmexclass::proxy::method::Context& context) {
   createAsynchronous(context, AsynchronousInstrumentType::ObservableUpDownCounter);
}

void MeterProxy::createObservableGauge(libmexclass::proxy::method::Context& context) {
   createAsynchronous(context, AsynchronousInstrumentType::ObservableGauge);
}
} // namespace libmexclass::opentelemetry
