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
    // this constructor should only be used by getTextMapPropagator
    TextMapPropagatorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments)
	    : CppPropagator(context_propagation::GlobalTextMapPropagator::GetGlobalPropagator())
    {
        registerMethods();
    }

    // default constructor should only be called by subclass constructors
    TextMapPropagatorProxy()
    {
        registerMethods();
    }

    void extract(libmexclass::proxy::method::Context& context);

    void inject(libmexclass::proxy::method::Context& context);

    void setTextMapPropagator(libmexclass::proxy::method::Context& context) {
	    context_propagation::GlobalTextMapPropagator::SetGlobalPropagator(CppPropagator);
    }

  private:
    void registerMethods() {
        REGISTER_METHOD(TextMapPropagatorProxy, extract);
        REGISTER_METHOD(TextMapPropagatorProxy, inject);
        REGISTER_METHOD(TextMapPropagatorProxy, setTextMapPropagator);
    }

  protected:
    nostd::shared_ptr<context_propagation::TextMapPropagator> CppPropagator;
};
} // namespace libmexclass::opentelemetry
