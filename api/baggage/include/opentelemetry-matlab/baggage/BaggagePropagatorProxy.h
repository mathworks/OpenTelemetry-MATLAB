// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/context/propagation/TextMapPropagatorProxy.h"

#include "opentelemetry/baggage/propagation/baggage_propagator.h"

namespace baggage_propagation = opentelemetry::baggage::propagation;
namespace context_propagation = opentelemetry::context::propagation;

namespace libmexclass::opentelemetry {
class BaggagePropagatorProxy : public TextMapPropagatorProxy {
  public:
    BaggagePropagatorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments)
    {
        CppPropagator = nostd::shared_ptr<context_propagation::TextMapPropagator>(new baggage_propagation::BaggagePropagator());
    }

    // getUniquePtrCopy is used by CompositePropagator, which needs a unique_ptr instance
    // Takes the BaggagePropagator object inside the shared_ptr, make a copy, and wrap the copy in a unique_ptr 
    virtual std::unique_ptr<context_propagation::TextMapPropagator> getUniquePtrCopy() override {
        return std::unique_ptr<context_propagation::TextMapPropagator>(
			new baggage_propagation::BaggagePropagator(
				*static_cast<baggage_propagation::BaggagePropagator*>(CppPropagator.get())));
    }
};
} // namespace libmexclass::opentelemetry
