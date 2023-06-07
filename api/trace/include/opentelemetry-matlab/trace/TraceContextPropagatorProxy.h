// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/context/propagation/TextMapPropagatorProxy.h"

#include "opentelemetry/trace/propagation/http_trace_context.h"

namespace trace_propagation = opentelemetry::trace::propagation;
namespace context_propagation = opentelemetry::context::propagation;

namespace libmexclass::opentelemetry {
class TraceContextPropagatorProxy : public TextMapPropagatorProxy {
  public:
    TraceContextPropagatorProxy() : TextMapPropagatorProxy(nostd::shared_ptr<context_propagation::TextMapPropagator>(
			    new trace_propagation::HttpTraceContext())) {}

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<TraceContextPropagatorProxy>();
    }

    // getUniquePtrCopy is used by CompositePropagator, which needs a unique_ptr instance
    // Takes the BaggagePropagator object inside the shared_ptr, make a copy, and wrap the copy in a unique_ptr 
    virtual std::unique_ptr<context_propagation::TextMapPropagator> getUniquePtrCopy() override {
        return std::unique_ptr<context_propagation::TextMapPropagator>(
			new trace_propagation::HttpTraceContext(
				*static_cast<trace_propagation::HttpTraceContext*>(CppPropagator.get())));
    }
};
} // namespace libmexclass::opentelemetry
