// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/trace/tracer.h"

namespace trace_api = opentelemetry::trace;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class TracerProxy : public libmexclass::proxy::Proxy {
  public:
    TracerProxy(nostd::shared_ptr<trace_api::Tracer> tr) : CppTracer(tr) {
        REGISTER_METHOD(TracerProxy, startSpan);
    }

    void startSpan(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<trace_api::Tracer> CppTracer;
};
} // namespace libmexclass::opentelemetry
