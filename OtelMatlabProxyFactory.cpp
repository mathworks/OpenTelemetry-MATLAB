// Copyright 2023-2025 The MathWorks, Inc.

#include "OtelMatlabProxyFactory.h"

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/trace/TracerProxy.h"
#include "opentelemetry-matlab/trace/SpanProxy.h"
//#include "opentelemetry-matlab/trace/ScopeProxy.h"
#include "opentelemetry-matlab/trace/SpanContextProxy.h"
#include "opentelemetry-matlab/trace/TraceContextPropagatorProxy.h"
#include "opentelemetry-matlab/trace/NoOpTracerProviderProxy.h"
#include "opentelemetry-matlab/metrics/NoOpMeterProviderProxy.h"
#include "opentelemetry-matlab/logs/LoggerProviderProxy.h"
#include "opentelemetry-matlab/logs/NoOpLoggerProviderProxy.h"
#include "opentelemetry-matlab/context/propagation/TextMapCarrierProxy.h"
#include "opentelemetry-matlab/context/propagation/TextMapPropagatorProxy.h"
#include "opentelemetry-matlab/context/propagation/CompositePropagatorProxy.h"
#include "opentelemetry-matlab/context/ContextProxy.h"
#include "opentelemetry-matlab/context/TokenProxy.h"
#include "opentelemetry-matlab/baggage/BaggageProxy.h"
#include "opentelemetry-matlab/baggage/BaggagePropagatorProxy.h"
#include "opentelemetry-matlab/sdk/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/sdk/trace/SimpleSpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/BatchSpanProcessorProxy.h"
#include "opentelemetry-matlab/sdk/trace/AlwaysOnSamplerProxy.h"
#include "opentelemetry-matlab/sdk/trace/AlwaysOffSamplerProxy.h"
#include "opentelemetry-matlab/sdk/trace/TraceIdRatioBasedSamplerProxy.h"
#include "opentelemetry-matlab/sdk/trace/ParentBasedSamplerProxy.h"
#include "opentelemetry-matlab/sdk/metrics/MeterProviderProxy.h"
#include "opentelemetry-matlab/sdk/metrics/ViewProxy.h"
#include "opentelemetry-matlab/sdk/metrics/PeriodicExportingMetricReaderProxy.h"
#include "opentelemetry-matlab/sdk/logs/LoggerProviderProxy.h"
#include "opentelemetry-matlab/sdk/logs/SimpleLogRecordProcessorProxy.h"
#include "opentelemetry-matlab/sdk/logs/BatchLogRecordProcessorProxy.h"
#include "opentelemetry-matlab/sdk/common/InternalLogHandlerProxy.h"
#ifdef WITH_OTLP_HTTP
    #include "opentelemetry-matlab/exporters/otlp/OtlpHttpSpanExporterProxy.h"
    #include "opentelemetry-matlab/exporters/otlp/OtlpHttpMetricExporterProxy.h"
    #include "opentelemetry-matlab/exporters/otlp/OtlpHttpLogRecordExporterProxy.h"
#endif
#ifdef WITH_OTLP_GRPC
    #include "opentelemetry-matlab/exporters/otlp/OtlpGrpcSpanExporterProxy.h"
    #include "opentelemetry-matlab/exporters/otlp/OtlpGrpcMetricExporterProxy.h"
    #include "opentelemetry-matlab/exporters/otlp/OtlpGrpcLogRecordExporterProxy.h"
#endif
#ifdef WITH_OTLP_FILE
    #include "opentelemetry-matlab/exporters/otlp/OtlpFileSpanExporterProxy.h"
    #include "opentelemetry-matlab/exporters/otlp/OtlpFileMetricExporterProxy.h"
    #include "opentelemetry-matlab/exporters/otlp/OtlpFileLogRecordExporterProxy.h"
#endif

libmexclass::proxy::MakeResult
OtelMatlabProxyFactory::make_proxy(const libmexclass::proxy::ClassName& class_name,
                               const libmexclass::proxy::FunctionArguments& constructor_arguments) {

    REGISTER_PROXY(libmexclass.opentelemetry.LoggerProviderProxy, libmexclass::opentelemetry::LoggerProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.MeterProviderProxy, libmexclass::opentelemetry::MeterProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.TracerProviderProxy, libmexclass::opentelemetry::TracerProviderProxy);
    //REGISTER_PROXY(libmexclass.opentelemetry.TracerProxy, libmexclass::opentelemetry::TracerProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.SpanProxy, libmexclass::opentelemetry::SpanProxy);
    //REGISTER_PROXY(libmexclass.opentelemetry.ScopeProxy, libmexclass::opentelemetry::ScopeProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.SpanContextProxy, libmexclass::opentelemetry::SpanContextProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.NoOpTracerProviderProxy, libmexclass::opentelemetry::NoOpTracerProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.NoOpMeterProviderProxy, libmexclass::opentelemetry::NoOpMeterProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.NoOpLoggerProviderProxy, libmexclass::opentelemetry::NoOpLoggerProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.TextMapCarrierProxy, libmexclass::opentelemetry::TextMapCarrierProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.ContextProxy, libmexclass::opentelemetry::ContextProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.TokenProxy, libmexclass::opentelemetry::TokenProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.TextMapPropagatorProxy, libmexclass::opentelemetry::TextMapPropagatorProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.CompositePropagatorProxy, libmexclass::opentelemetry::CompositePropagatorProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.TraceContextPropagatorProxy, libmexclass::opentelemetry::TraceContextPropagatorProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.BaggageProxy, libmexclass::opentelemetry::BaggageProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.BaggagePropagatorProxy, libmexclass::opentelemetry::BaggagePropagatorProxy);

    REGISTER_PROXY(libmexclass.opentelemetry.sdk.TracerProviderProxy, libmexclass::opentelemetry::sdk::TracerProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.SimpleSpanProcessorProxy, libmexclass::opentelemetry::sdk::SimpleSpanProcessorProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.BatchSpanProcessorProxy, libmexclass::opentelemetry::sdk::BatchSpanProcessorProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.AlwaysOnSamplerProxy, libmexclass::opentelemetry::sdk::AlwaysOnSamplerProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.AlwaysOffSamplerProxy, libmexclass::opentelemetry::sdk::AlwaysOffSamplerProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.TraceIdRatioBasedSamplerProxy, libmexclass::opentelemetry::sdk::TraceIdRatioBasedSamplerProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.ParentBasedSamplerProxy, libmexclass::opentelemetry::sdk::ParentBasedSamplerProxy);

    REGISTER_PROXY(libmexclass.opentelemetry.sdk.MeterProviderProxy, libmexclass::opentelemetry::sdk::MeterProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.ViewProxy, libmexclass::opentelemetry::sdk::ViewProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.PeriodicExportingMetricReaderProxy, libmexclass::opentelemetry::sdk::PeriodicExportingMetricReaderProxy);

    REGISTER_PROXY(libmexclass.opentelemetry.sdk.LoggerProviderProxy, libmexclass::opentelemetry::sdk::LoggerProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.SimpleLogRecordProcessorProxy, libmexclass::opentelemetry::sdk::SimpleLogRecordProcessorProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.BatchLogRecordProcessorProxy, libmexclass::opentelemetry::sdk::BatchLogRecordProcessorProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.InternalLogHandlerProxy, libmexclass::opentelemetry::sdk::InternalLogHandlerProxy);

    #ifdef WITH_OTLP_HTTP
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpHttpSpanExporterProxy, libmexclass::opentelemetry::exporters::OtlpHttpSpanExporterProxy);
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpHttpMetricExporterProxy, libmexclass::opentelemetry::exporters::OtlpHttpMetricExporterProxy);
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpHttpLogRecordExporterProxy, libmexclass::opentelemetry::exporters::OtlpHttpLogRecordExporterProxy);
    #endif
    #ifdef WITH_OTLP_GRPC
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpGrpcSpanExporterProxy, libmexclass::opentelemetry::exporters::OtlpGrpcSpanExporterProxy);
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpGrpcMetricExporterProxy, libmexclass::opentelemetry::exporters::OtlpGrpcMetricExporterProxy);
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpGrpcLogRecordExporterProxy, libmexclass::opentelemetry::exporters::OtlpGrpcLogRecordExporterProxy);
    #endif
    #ifdef WITH_OTLP_FILE
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpFileSpanExporterProxy, libmexclass::opentelemetry::exporters::OtlpFileSpanExporterProxy);
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpFileMetricExporterProxy, libmexclass::opentelemetry::exporters::OtlpFileMetricExporterProxy);
        REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpFileLogRecordExporterProxy, libmexclass::opentelemetry::exporters::OtlpFileLogRecordExporterProxy);
    #endif
    return nullptr;
}
