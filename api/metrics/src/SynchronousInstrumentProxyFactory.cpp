// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/SynchronousInstrumentProxyFactory.h"
#include "opentelemetry-matlab/metrics/CounterProxy.h"
#include "opentelemetry-matlab/metrics/HistogramProxy.h"
#include "opentelemetry-matlab/metrics/UpDownCounterProxy.h"


namespace libmexclass::opentelemetry {
std::shared_ptr<libmexclass::proxy::Proxy> SynchronousInstrumentProxyFactory::create(SynchronousInstrumentType type, 
		const std::string& name, const std::string& description, const std::string& unit) {
   std::shared_ptr<libmexclass::proxy::Proxy> proxy;
   switch(type) {
       case SynchronousInstrumentType::Counter:
       {
               nostd::shared_ptr<metrics_api::Counter<double> > ct = std::move(CppMeter->CreateDoubleCounter(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new CounterProxy(ct));
       }
	       break;
       case SynchronousInstrumentType::UpDownCounter:
       {
               nostd::shared_ptr<metrics_api::UpDownCounter<double> > udct = std::move(CppMeter->CreateDoubleUpDownCounter(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new UpDownCounterProxy(udct));
       }
	       break;
       case SynchronousInstrumentType::Histogram:
       {
               nostd::shared_ptr<metrics_api::Histogram<double> > hist = std::move(CppMeter->CreateDoubleHistogram(name, description, unit));
               proxy = std::shared_ptr<libmexclass::proxy::Proxy>(new HistogramProxy(hist));
       }
	       break;
   }
   return proxy;
}


} // namespace libmexclass::opentelemetry
