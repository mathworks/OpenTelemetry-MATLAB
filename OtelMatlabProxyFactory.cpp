// Copyright 2023 The MathWorks, Inc.

#include "OtelMatlabProxyFactory.h"

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"
#include "opentelemetry-matlab/trace/TracerProxy.h"
#include "opentelemetry-matlab/trace/SpanProxy.h"
//#include "opentelemetry-matlab/trace/ScopeProxy.h"
#include "opentelemetry-matlab/trace/SpanContextProxy.h"
#include "opentelemetry-matlab/sdk/trace/TracerProviderProxy.h"

std::shared_ptr<libmexclass::proxy::Proxy>
OtelMatlabProxyFactory::make_proxy(const libmexclass::proxy::ClassName& class_name,
                               const libmexclass::proxy::FunctionArguments& constructor_arguments) {

    REGISTER_PROXY(libmexclass.opentelemetry.TracerProviderProxy, libmexclass::opentelemetry::TracerProviderProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.TracerProxy, libmexclass::opentelemetry::TracerProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.SpanProxy, libmexclass::opentelemetry::SpanProxy);
    //REGISTER_PROXY(libmexclass.opentelemetry.ScopeProxy, libmexclass::opentelemetry::ScopeProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.SpanContextProxy, libmexclass::opentelemetry::SpanContextProxy);
    REGISTER_PROXY(libmexclass.opentelemetry.sdk.TracerProviderProxy, libmexclass::opentelemetry::sdk::TracerProviderProxy);
    return nullptr;
}
