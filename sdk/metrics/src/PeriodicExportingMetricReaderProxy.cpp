// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"
#include "opentelemetry-matlab/sdk/metrics/PeriodicExportingMetricReaderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"


namespace libmexclass::opentelemetry::sdk {

PeriodicExportingMetricReaderProxy::PeriodicExportingMetricReaderProxy(std::shared_ptr<MetricExporterProxy> exporter, 
                                                                        double interval, double timeout)
	: MetricExporter(exporter) {

    if (interval > 0) {
        CppOptions.export_interval_millis = std::chrono::milliseconds(static_cast<int64_t>(interval));
    } 
    if (timeout > 0) {
        CppOptions.export_timeout_millis = std::chrono::milliseconds(static_cast<int64_t>(timeout));
    }
   
    REGISTER_METHOD(PeriodicExportingMetricReaderProxy, getDefaultOptionValues);
}


libmexclass::proxy::MakeResult PeriodicExportingMetricReaderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments){
    matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
    libmexclass::proxy::ID exporterid = exporterid_mda[0];
    std::shared_ptr<MetricExporterProxy> exporter = std::static_pointer_cast<MetricExporterProxy>(
        libmexclass::proxy::ProxyManager::getProxy(exporterid));
    matlab::data::TypedArray<double> interval_mda = constructor_arguments[1];
    double interval = interval_mda[0];
    matlab::data::TypedArray<double> timeout_mda = constructor_arguments[2];
    double timeout = timeout_mda[0];
    
    return std::make_shared<PeriodicExportingMetricReaderProxy>(exporter, interval, timeout);
}


std::unique_ptr<metric_sdk::MetricReader> PeriodicExportingMetricReaderProxy::getInstance(){
    return std::unique_ptr<metric_sdk::MetricReader> (
        metric_sdk::PeriodicExportingMetricReaderFactory::Create(std::move(MetricExporter->getInstance()), CppOptions));
}


void PeriodicExportingMetricReaderProxy::getDefaultOptionValues(libmexclass::proxy::method::Context& context){
    metric_sdk::PeriodicExportingMetricReaderOptions options;
    matlab::data::ArrayFactory factory;
    auto interval_mda = factory.createScalar<double>(static_cast<double>(
			    options.export_interval_millis.count()));
    auto timeout_mda = factory.createScalar<double>(static_cast<double>(
			    options.export_timeout_millis.count()));
    context.outputs[0] = interval_mda;
    context.outputs[1] = timeout_mda;
}

} // namespace libmexclass::opentelemetry
