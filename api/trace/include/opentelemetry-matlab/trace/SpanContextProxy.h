// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/trace/span_context.h"

namespace trace_api = opentelemetry::trace;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class SpanContextProxy : public libmexclass::proxy::Proxy {
  public:
    SpanContextProxy(trace_api::SpanContext sc) : CppSpanContext{std::move(sc)}   
    {
        REGISTER_METHOD(SpanContextProxy, getTraceId);
        REGISTER_METHOD(SpanContextProxy, getSpanId);
        REGISTER_METHOD(SpanContextProxy, getTraceState);
        REGISTER_METHOD(SpanContextProxy, getTraceFlags);
        REGISTER_METHOD(SpanContextProxy, isSampled);
        REGISTER_METHOD(SpanContextProxy, isValid);
        REGISTER_METHOD(SpanContextProxy, isRemote);
    }

    // dummy constructor that wraps around an invalid context, to satisfy proxy registration
    SpanContextProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) :
	CppSpanContext{false,false} {
    }

    trace_api::SpanContext getInstance() {
        return CppSpanContext;
    }

    void getTraceId(libmexclass::proxy::method::Context& context);

    void getSpanId(libmexclass::proxy::method::Context& context);

    void getTraceState(libmexclass::proxy::method::Context& context);

    void getTraceFlags(libmexclass::proxy::method::Context& context);

    void isSampled(libmexclass::proxy::method::Context& context);

    void isValid(libmexclass::proxy::method::Context& context);

    void isRemote(libmexclass::proxy::method::Context& context);

  private:

    trace_api::SpanContext CppSpanContext;
};
} // namespace libmexclass::opentelemetry
