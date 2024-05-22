// Copyright 2023-2024 The MathWorks, Inc.

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
        REGISTER_METHOD(TracerProxy, startSpanWithNameOnly);
        REGISTER_METHOD(TracerProxy, startSpanWithNameAndOptions);
        REGISTER_METHOD(TracerProxy, startSpanWithNameAndAttributes);
        REGISTER_METHOD(TracerProxy, startSpanWithNameOptionsAttributes);
    }

    void startSpanWithNameOnly(libmexclass::proxy::method::Context& context);

    void startSpanWithNameAndOptions(libmexclass::proxy::method::Context& context);

    void startSpanWithNameAndAttributes(libmexclass::proxy::method::Context& context);

    void startSpanWithNameOptionsAttributes(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<trace_api::Tracer> CppTracer;
};
} // namespace libmexclass::opentelemetry
