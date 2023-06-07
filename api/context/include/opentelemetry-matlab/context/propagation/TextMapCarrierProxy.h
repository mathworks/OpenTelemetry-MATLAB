// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/context/propagation/HttpTextMapCarrier.h"

namespace libmexclass::opentelemetry {
class TextMapCarrierProxy : public libmexclass::proxy::Proxy {
  public:
    TextMapCarrierProxy(const HttpTextMapCarrier& carrier) : CppCarrier(carrier) {
        REGISTER_METHOD(TextMapCarrierProxy, getHeaders);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    HttpTextMapCarrier getInstance() {
        return CppCarrier;
    }

    void getHeaders(libmexclass::proxy::method::Context& context);

  private:
    HttpTextMapCarrier CppCarrier;
};
} // namespace libmexclass::opentelemetry
