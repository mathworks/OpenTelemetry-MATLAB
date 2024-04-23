// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/logs/logger.h"

namespace logs_api = opentelemetry::logs;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class LoggerProxy : public libmexclass::proxy::Proxy {
  public:
    LoggerProxy(nostd::shared_ptr<logs_api::Logger> lg) : CppLogger(lg) {
        REGISTER_METHOD(LoggerProxy, emitLogRecord);
    }

    void emitLogRecord(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<logs_api::Logger> CppLogger;
};
} // namespace libmexclass::opentelemetry
