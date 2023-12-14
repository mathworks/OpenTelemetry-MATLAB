// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry-matlab/sdk/metrics/MetricExporterProxy.h"
#include "opentelemetry-matlab/sdk/metrics/PeriodicExportingMetricReaderProxy.h"

#include "libmexclass/proxy/ProxyManager.h"


namespace libmexclass::opentelemetry::sdk {

PeriodicExportingMetricReaderProxy::PeriodicExportingMetricReaderProxy(std::shared_ptr<MetricExporterProxy> exporter)
	: MetricExporter(exporter) {
    REGISTER_METHOD(PeriodicExportingMetricReaderProxy, setInterval);
    REGISTER_METHOD(PeriodicExportingMetricReaderProxy, setTimeout);
}


libmexclass::proxy::MakeResult PeriodicExportingMetricReaderProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments){
    matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
    libmexclass::proxy::ID exporterid = exporterid_mda[0];
    std::shared_ptr<MetricExporterProxy> exporter = std::static_pointer_cast<MetricExporterProxy>(
        libmexclass::proxy::ProxyManager::getProxy(exporterid));
    
    return std::make_shared<PeriodicExportingMetricReaderProxy>(exporter);
}


std::unique_ptr<metric_sdk::MetricReader> PeriodicExportingMetricReaderProxy::getInstance(){
    return std::unique_ptr<metric_sdk::MetricReader> (
        metric_sdk::PeriodicExportingMetricReaderFactory::Create(std::move(MetricExporter->getInstance()), CppOptions));
}


void PeriodicExportingMetricReaderProxy::setInterval(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> interval_mda = context.inputs[0];
    CppOptions.export_interval_millis = std::chrono::milliseconds(static_cast<int64_t>(interval_mda[0]));
}

void PeriodicExportingMetricReaderProxy::setTimeout(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> timeout_mda = context.inputs[0];
    CppOptions.export_timeout_millis = std::chrono::milliseconds(static_cast<int64_t>(timeout_mda[0]));
}

} // namespace libmexclass::opentelemetry
