// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/context/propagation/TextMapPropagatorProxy.h"

#include "opentelemetry/trace/propagation/http_trace_context.h"

namespace trace_propagation = opentelemetry::trace::propagation;

namespace libmexclass::opentelemetry {
class TraceContextPropagatorProxy : public TextMapPropagatorProxy {
  public:
    TraceContextPropagatorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments)
    {
        CppPropagator = nostd::shared_ptr<context_propagation::TextMapPropagator>(new trace_propagation::HttpTraceContext());
    }
};
} // namespace libmexclass::opentelemetry
