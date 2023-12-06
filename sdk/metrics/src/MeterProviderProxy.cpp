// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry/sdk/metrics/instruments.h"
#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"
#include "opentelemetry-matlab/sdk/metrics/PeriodicExportingMetricReaderProxy.h"
#include "opentelemetry-matlab/sdk/metrics/ViewProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include <chrono>
#include <string.h>

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult MeterProviderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    
    libmexclass::proxy::MakeResult out;
    if (constructor_arguments.getNumberOfElements() == 1)  {
        // if only one input, assume it is an API Meter Provider to support type conversion
        matlab::data::TypedArray<uint64_t> mpid_mda = constructor_arguments[0];
        libmexclass::proxy::ID mpid = mpid_mda[0];
        auto mp = std::static_pointer_cast<libmexclass::opentelemetry::MeterProviderProxy>(
            libmexclass::proxy::ProxyManager::getProxy(mpid))->getInstance();
        // check if input can be cast to an SDK Meter Provider 
        auto mpsdk = dynamic_cast<metrics_sdk::MeterProvider*>(mp.get());
        if (mpsdk == nullptr) {
          return libmexclass::error::Error{"opentelemetry:sdk:metrics:Cleanup:UnsetGlobalInstance", 
          "Clean up operations are not supported if global MeterProvider instance is not set."};
        }
        out = std::make_shared<MeterProviderProxy>(nostd::shared_ptr<metrics_api::MeterProvider>(mp));
    } else {
        matlab::data::TypedArray<uint64_t> readerid_mda = constructor_arguments[0];
        libmexclass::proxy::ID readerid = readerid_mda[0];
        
        matlab::data::StringArray resourcenames_mda = constructor_arguments[1];
        size_t nresourceattrs = resourcenames_mda.getNumberOfElements();
        matlab::data::CellArray resourcevalues_mda = constructor_arguments[2];
    
        auto resource_custom = createResource(resourcenames_mda, resourcevalues_mda);

        auto reader = std::static_pointer_cast<PeriodicExportingMetricReaderProxy>(
	            libmexclass::proxy::ProxyManager::getProxy(readerid))->getInstance();
        
        auto view = metrics_sdk::ViewRegistryFactory::Create();
        auto p = metrics_sdk::MeterProviderFactory::Create(std::move(view), resource_custom);
        auto *p_sdk = static_cast<metrics_sdk::MeterProvider *>(p.get());
        p_sdk->AddMetricReader(std::move(reader));

        auto p_out = nostd::shared_ptr<metrics_api::MeterProvider>(std::move(p));
        out = std::make_shared<MeterProviderProxy>(p_out);
    }
    return out;
}

void MeterProviderProxy::addMetricReader(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> readerid_mda = context.inputs[0];
    libmexclass::proxy::ID readerid = readerid_mda[0];

    static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).AddMetricReader(
		    std::static_pointer_cast<PeriodicExportingMetricReaderProxy>(
			    libmexclass::proxy::ProxyManager::getProxy(readerid))->getInstance());
   return;
}

void MeterProviderProxy::addView(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> viewid_mda = context.inputs[0];
    libmexclass::proxy::ID viewid = viewid_mda[0];
    
    // auto i = std::static_pointer_cast<ViewProxy>(libmexclass::proxy::ProxyManager::getProxy(viewid))->getInstrumentSelector(context);
    // if((int)(i->GetInstrumentType())!=0){
    //     exit(0);
    // }
    // auto instrument_name = "mycounter";
    // auto instrument_name_view = nostd::string_view(instrument_name);
    // if(!i->GetNameFilter()->Match(instrument_name_view)){
    //     exit(0);
    // }
    // auto instrument_unit = "unit";
    // auto instrument_unit_view = nostd::string_view(instrument_unit);
    // if(!i->GetUnitFilter()->Match(instrument_unit_view)){
    //     exit(0);
    // }
    // auto m = std::static_pointer_cast<ViewProxy>(libmexclass::proxy::ProxyManager::getProxy(viewid))->getMeterSelector(context);
    // auto meter_name = "mymeter";
    // auto meter_name_view = nostd::string_view(meter_name);
    // if(!m->GetNameFilter()->Match(meter_name_view)){
    //     exit(0);
    // }
    // auto meter_version = "1.2.0";
    // auto meter_version_view = nostd::string_view(meter_version);
    // if(!m->GetVersionFilter()->Match(meter_version_view)){
    //     exit(0);
    // }
    // auto meter_schema = "";
    // auto meter_schema_view = nostd::string_view(meter_schema);
    // if(!m->GetSchemaFilter()->Match(meter_schema_view)){
    //     exit(0);
    // }
    // auto v = std::static_pointer_cast<ViewProxy>(libmexclass::proxy::ProxyManager::getProxy(viewid))->getView(context);
    // if(v->GetName().compare("View")!=0){
    //     exit(0);
    // }
    // if(v->GetDescription().compare("description")!=0){
    //     exit(0);
    // }
    // if((int)(v->GetAggregationType())!=0){
    //     exit(0);
    // }

    static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).AddView(
		    std::static_pointer_cast<ViewProxy>(libmexclass::proxy::ProxyManager::getProxy(viewid))->getInstrumentSelector(context),
            std::static_pointer_cast<ViewProxy>(libmexclass::proxy::ProxyManager::getProxy(viewid))->getMeterSelector(context),
		    std::static_pointer_cast<ViewProxy>(libmexclass::proxy::ProxyManager::getProxy(viewid))->getView(context));
   return;
}

void MeterProviderProxy::shutdown(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;
    auto result_mda = factory.createScalar(static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).Shutdown());
    context.outputs[0] = result_mda;
    nostd::shared_ptr<metrics_api::MeterProvider> noop(new metrics_api::NoopMeterProvider);
    CppMeterProvider.swap(noop);
}

void MeterProviderProxy::forceFlush(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;

    if (context.inputs.getNumberOfElements() == 0) {
        context.outputs[0] = factory.createScalar(static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).ForceFlush());
    } else {  // number of inputs > 0
        matlab::data::TypedArray<double> timeout_mda = context.inputs[0];
        auto timeout = std::chrono::microseconds(timeout_mda[0]);
        context.outputs[0] = factory.createScalar(static_cast<metrics_sdk::MeterProvider&>(*CppMeterProvider).ForceFlush(timeout));
    }
}


} // namespace libmexclass::opentelemetry
