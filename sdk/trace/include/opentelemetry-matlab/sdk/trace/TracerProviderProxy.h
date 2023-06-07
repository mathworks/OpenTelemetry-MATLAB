// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"

namespace libmexclass::opentelemetry::sdk {
class TracerProviderProxy : public libmexclass::opentelemetry::TracerProviderProxy {
  public:
    TracerProviderProxy(nostd::shared_ptr<trace_api::TracerProvider> tp) : libmexclass::opentelemetry::TracerProviderProxy(tp) {
        REGISTER_METHOD(TracerProviderProxy, addSpanProcessor);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    void addSpanProcessor(libmexclass::proxy::method::Context& context);
};
} // namespace libmexclass::opentelemetry
