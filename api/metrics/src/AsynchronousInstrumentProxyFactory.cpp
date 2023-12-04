// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxyFactory.h"
#include "opentelemetry-matlab/metrics/ObservableCounterProxy.h"
#include "opentelemetry-matlab/metrics/ObservableUpDownCounterProxy.h"
#include "opentelemetry-matlab/metrics/ObservableGaugeProxy.h"

namespace libmexclass::opentelemetry {
std::shared_ptr<libmexclass::proxy::Proxy> AsynchronousInstrumentProxyFactory::create(AsynchronousInstrumentType type, 
		const std::string& callback, const std::string& name, const std::string& description, const std::string& unit) {
   std::shared_ptr<libmexclass::proxy::Proxy> proxy;
   switch(type) {
       case AsynchronousInstrumentType::ObservableCounter:
       {
               nostd::shared_ptr<metrics_api::ObservableInstrument > ct = std::move(CppMeter->CreateDoubleObservableCounter(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ObservableCounterProxy(ct));
       }
	       break;
       case AsynchronousInstrumentType::ObservableUpDownCounter:
       {
               nostd::shared_ptr<metrics_api::ObservableInstrument > udct = std::move(CppMeter->CreateDoubleObservableUpDownCounter(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ObservableUpDownCounterProxy(udct));
       }
	       break;
       case AsynchronousInstrumentType::ObservableGauge:
       {
               nostd::shared_ptr<metrics_api::ObservableInstrument > g = std::move(CppMeter->CreateDoubleObservableGauge(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ObservableGaugeProxy(g));
       }
	       break;
   }
   // add callback
   if (!callback.empty()) {
       std::static_pointer_cast<AsynchronousInstrumentProxy>(proxy)->addCallback_helper(callback);
   }
   return proxy;
}

} // namespace libmexclass::opentelemetry
