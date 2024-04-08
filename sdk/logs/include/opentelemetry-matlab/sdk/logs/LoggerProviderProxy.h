// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/logs/LoggerProviderProxy.h"

namespace libmexclass::opentelemetry::sdk {
class LoggerProviderProxy : public libmexclass::opentelemetry::LoggerProviderProxy {
  public:
    LoggerProviderProxy(nostd::shared_ptr<logs_api::LoggerProvider> lp) : libmexclass::opentelemetry::LoggerProviderProxy(lp) {
        REGISTER_METHOD(LoggerProviderProxy, addProcessor);
        REGISTER_METHOD(LoggerProviderProxy, shutdown);
        REGISTER_METHOD(LoggerProviderProxy, forceFlush);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    void addProcessor(libmexclass::proxy::method::Context& context);

    void shutdown(libmexclass::proxy::method::Context& context);

    void forceFlush(libmexclass::proxy::method::Context& context);
};
} // namespace libmexclass::opentelemetry
