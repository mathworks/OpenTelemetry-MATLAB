// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/logs/logger_provider.h"
#include "opentelemetry/logs/provider.h"
#include "opentelemetry/logs/noop.h"

namespace logs_api = opentelemetry::logs;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class LoggerProviderProxy : public libmexclass::proxy::Proxy {
  public:
    LoggerProviderProxy(nostd::shared_ptr<logs_api::LoggerProvider> lp) : CppLoggerProvider(lp) {
        REGISTER_METHOD(LoggerProviderProxy, getLogger);
        REGISTER_METHOD(LoggerProviderProxy, setLoggerProvider);
        REGISTER_METHOD(LoggerProviderProxy, postShutdown);
    }

    // Static make method should only be used by getLoggerProvider. It gets the global instance 
    // instead of creating a new instance
    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<LoggerProviderProxy>(logs_api::Provider::GetLoggerProvider());
    }

    void getLogger(libmexclass::proxy::method::Context& context);

    void setLoggerProvider(libmexclass::proxy::method::Context& context);

    nostd::shared_ptr<logs_api::LoggerProvider> getInstance() {
        return CppLoggerProvider;
    }

    void postShutdown(libmexclass::proxy::method::Context& context) {
    //	// Replace logger provider with a no-op instance. Subsequent logs won't be recorded
    	nostd::shared_ptr<logs_api::LoggerProvider> noop(new logs_api::NoopLoggerProvider);
        CppLoggerProvider.swap(noop);
    }

  protected:
    nostd::shared_ptr<logs_api::LoggerProvider> CppLoggerProvider;
};
} // namespace libmexclass::opentelemetry
