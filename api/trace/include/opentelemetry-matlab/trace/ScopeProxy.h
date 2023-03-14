// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/trace/scope.h"

namespace trace_api = opentelemetry::trace;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class ScopeProxy : public libmexclass::proxy::Proxy {
  public:
    ScopeProxy(nostd::shared_ptr<trace_api::Span> span) : CppScope{span}   {}


  private:
    trace_api::Scope CppScope;
};
} // namespace libmexclass::opentelemetry
