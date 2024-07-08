// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"

namespace libmexclass::opentelemetry::sdk {
class InternalLogHandlerProxy: public libmexclass::proxy::Proxy {
  public:
    InternalLogHandlerProxy() {
        REGISTER_METHOD(InternalLogHandlerProxy, setLogLevel);
        REGISTER_METHOD(InternalLogHandlerProxy, getLogLevel);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<InternalLogHandlerProxy>();
    }

    void setLogLevel(libmexclass::proxy::method::Context& context);

    void getLogLevel(libmexclass::proxy::method::Context& context);
};
} // namespace libmexclass::opentelemetry
