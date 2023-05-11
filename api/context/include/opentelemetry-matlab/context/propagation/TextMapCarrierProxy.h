// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/context/propagation/HttpTextMapCarrier.h"

namespace libmexclass::opentelemetry {
class TextMapCarrierProxy : public libmexclass::proxy::Proxy {
  public:
    TextMapCarrierProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    TextMapCarrierProxy(const HttpTextMapCarrier& carrier) : CppCarrier(carrier) {
        registerMethods();
    }

    HttpTextMapCarrier getInstance() {
        return CppCarrier;
    }

    void getHeaders(libmexclass::proxy::method::Context& context);

  private:
    void registerMethods() {
        REGISTER_METHOD(TextMapCarrierProxy, getHeaders);
    }

    HttpTextMapCarrier CppCarrier;
};
} // namespace libmexclass::opentelemetry
