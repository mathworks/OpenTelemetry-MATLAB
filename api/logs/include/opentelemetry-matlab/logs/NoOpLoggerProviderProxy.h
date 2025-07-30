// Copyright 2025 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

#include "opentelemetry/logs/logger_provider.h"
#include "opentelemetry/logs/provider.h"
#include "opentelemetry/logs/noop.h"

namespace logs_api = opentelemetry::logs;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class NoOpLoggerProviderProxy : public libmexclass::proxy::Proxy {
  public:
    NoOpLoggerProviderProxy(nostd::shared_ptr<logs_api::LoggerProvider> lp) : CppLoggerProvider(lp) {
        // set as global LoggerProvider instance
        logs_api::Provider::SetLoggerProvider(CppLoggerProvider);
    } 

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<NoOpLoggerProviderProxy>(nostd::shared_ptr<logs_api::LoggerProvider>(new logs_api::NoopLoggerProvider()));
    }

  protected:
    nostd::shared_ptr<logs_api::LoggerProvider> CppLoggerProvider;
};
} // namespace libmexclass::opentelemetry
