// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/trace/span.h"

namespace trace_api = opentelemetry::trace;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class SpanProxy : public libmexclass::proxy::Proxy {
  public:
    SpanProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    void setInstance(nostd::shared_ptr<trace_api::Span> instance) {
        CppSpan = instance;
    }

    void endSpan(libmexclass::proxy::method::Context& context);

    void makeCurrent(libmexclass::proxy::method::Context& context);

    void setAttribute(libmexclass::proxy::method::Context& context);

    void addEvent(libmexclass::proxy::method::Context& context);

    void updateName(libmexclass::proxy::method::Context& context);

    void setStatus(libmexclass::proxy::method::Context& context);

    void getContext(libmexclass::proxy::method::Context& context);

    void isRecording(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<trace_api::Span> CppSpan;
};
} // namespace libmexclass::opentelemetry
