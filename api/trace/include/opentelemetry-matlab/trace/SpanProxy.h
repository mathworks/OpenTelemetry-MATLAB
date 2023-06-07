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
    SpanProxy(nostd::shared_ptr<trace_api::Span> span) : CppSpan(span) {
        REGISTER_METHOD(SpanProxy, endSpan);
        REGISTER_METHOD(SpanProxy, makeCurrent);
        REGISTER_METHOD(SpanProxy, setAttribute);
        REGISTER_METHOD(SpanProxy, addEvent);
        REGISTER_METHOD(SpanProxy, updateName);
        REGISTER_METHOD(SpanProxy, setStatus);
        REGISTER_METHOD(SpanProxy, getSpanContext);
        REGISTER_METHOD(SpanProxy, isRecording);
        REGISTER_METHOD(SpanProxy, insertSpan);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    void endSpan(libmexclass::proxy::method::Context& context);

    void makeCurrent(libmexclass::proxy::method::Context& context);

    void setAttribute(libmexclass::proxy::method::Context& context);

    void addEvent(libmexclass::proxy::method::Context& context);

    void updateName(libmexclass::proxy::method::Context& context);

    void setStatus(libmexclass::proxy::method::Context& context);

    void getSpanContext(libmexclass::proxy::method::Context& context);

    void isRecording(libmexclass::proxy::method::Context& context);

    void insertSpan(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<trace_api::Span> CppSpan;
};
} // namespace libmexclass::opentelemetry
