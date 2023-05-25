// Copyright 2023 The MathWorks, Inc.

#include "OtelMatlabProxyFactory.h"

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/trace/TracerProxy.h"
#include "opentelemetry-matlab/trace/SpanProxy.h"
//#include "opentelemetry-matlab/trace/ScopeProxy.h"
#include "opentelemetry-matlab/trace/SpanContextProxy.h"
#include "opentelemetry-matlab/trace/TraceContextPropagatorProxy.h"
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
#include "opentelemetry-matlab/exporters/otlp/OtlpHttpSpanExporterProxy.h"
#include "opentelemetry-matlab/exporters/otlp/OtlpGrpcSpanExporterProxy.h"

std::shared_ptr<libmexclass::proxy::Proxy>
OtelMatlabProxyFactory::make_proxy(const libmexclass::proxy::ClassName& class_name,
                               const libmexclass::proxy::FunctionArguments& constructor_arguments) {

    REGISTER_PROXY(libmexclass.opentelemetry.TracerProviderProxy, libmexclass::opentelemetry::TracerProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.TracerProxy, libmexclass::opentelemetry::TracerProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.SpanProxy, libmexclass::opentelemetry::SpanProxy);
    //REGISTER_PROXY(libmexclass.opentelemetry.ScopeProxy, libmexclass::opentelemetry::ScopeProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.SpanContextProxy, libmexclass::opentelemetry::SpanContextProxy);
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
    REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpHttpSpanExporterProxy, libmexclass::opentelemetry::exporters::OtlpHttpSpanExporterProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.exporters.OtlpGrpcSpanExporterProxy, libmexclass::opentelemetry::exporters::OtlpGrpcSpanExporterProxy);
    return nullptr;
}
