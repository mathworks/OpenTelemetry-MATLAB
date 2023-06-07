// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/context/propagation/text_map_propagator.h"
#include "opentelemetry/context/propagation/global_propagator.h"
#include "opentelemetry/nostd//shared_ptr.h"

namespace context_propagation = opentelemetry::context::propagation;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class TextMapPropagatorProxy : public libmexclass::proxy::Proxy {
  public:
    TextMapPropagatorProxy(nostd::shared_ptr<context_propagation::TextMapPropagator> prop)
	    : CppPropagator(prop)
    {
        REGISTER_METHOD(TextMapPropagatorProxy, extract);
        REGISTER_METHOD(TextMapPropagatorProxy, inject);
        REGISTER_METHOD(TextMapPropagatorProxy, setTextMapPropagator);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<TextMapPropagatorProxy>(context_propagation::GlobalTextMapPropagator::GetGlobalPropagator());
    }

    // getUniquePtrCopy is used by CompositePropagator, which needs a unique_ptr instance
    virtual std::unique_ptr<context_propagation::TextMapPropagator> getUniquePtrCopy() {
	// default behavior is to assert and return null
	assert(false);
        return nullptr;
    }

    void extract(libmexclass::proxy::method::Context& context);

    void inject(libmexclass::proxy::method::Context& context);

    void setTextMapPropagator(libmexclass::proxy::method::Context& context) {
	    context_propagation::GlobalTextMapPropagator::SetGlobalPropagator(CppPropagator);
    }

  protected:
    nostd::shared_ptr<context_propagation::TextMapPropagator> CppPropagator;
};
} // namespace libmexclass::opentelemetry
