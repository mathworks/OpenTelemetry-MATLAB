// Copyright 2023-2024 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxyFactory.h"
#include "opentelemetry-matlab/metrics/ObservableCounterProxy.h"
#include "opentelemetry-matlab/metrics/ObservableUpDownCounterProxy.h"
#include "opentelemetry-matlab/metrics/ObservableGaugeProxy.h"

namespace libmexclass::opentelemetry {
std::shared_ptr<libmexclass::proxy::Proxy> AsynchronousInstrumentProxyFactory::create(AsynchronousInstrumentType type, 
		const matlab::data::Array& callback, const std::string& name, const std::string& description, const std::string& unit, 
		const std::chrono::milliseconds& timeout) {
   std::shared_ptr<libmexclass::proxy::Proxy> proxy;
   switch(type) {
       case AsynchronousInstrumentType::ObservableCounter:
       {
               nostd::shared_ptr<metrics_api::ObservableInstrument > ct = std::move(CppMeter->CreateDoubleObservableCounter(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ObservableCounterProxy(ct, MexEngine));
       }
	       break;
       case AsynchronousInstrumentType::ObservableUpDownCounter:
       {
               nostd::shared_ptr<metrics_api::ObservableInstrument > udct = std::move(CppMeter->CreateDoubleObservableUpDownCounter(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ObservableUpDownCounterProxy(udct, MexEngine));
       }
	       break;
       case AsynchronousInstrumentType::ObservableGauge:
       {
               nostd::shared_ptr<metrics_api::ObservableInstrument > g = std::move(CppMeter->CreateDoubleObservableGauge(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ObservableGaugeProxy(g, MexEngine));
       }
	       break;
   }
   // add callback
   if (!callback.isEmpty()) {
       std::static_pointer_cast<AsynchronousInstrumentProxy>(proxy)->addCallback_helper(callback, timeout);
   }
   return proxy;
}

} // namespace libmexclass::opentelemetry
