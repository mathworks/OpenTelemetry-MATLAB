// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/context/propagation/TextMapPropagatorProxy.h"

namespace libmexclass::opentelemetry {
class CompositePropagatorProxy : public TextMapPropagatorProxy {
  public:
    CompositePropagatorProxy(nostd::shared_ptr<context_propagation::TextMapPropagator> prop) : TextMapPropagatorProxy(prop) {}

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);
};
} // namespace libmexclass::opentelemetry
