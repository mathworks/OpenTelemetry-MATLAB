// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/context/context.h"
#include "opentelemetry/context/runtime_context.h"
#include "opentelemetry/nostd/unique_ptr.h"

namespace context_api = opentelemetry::context;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class TokenProxy : public libmexclass::proxy::Proxy {
  public:
    TokenProxy() {}

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        return std::make_shared<TokenProxy>();
    }

    void setInstance(nostd::unique_ptr<context_api::Token>& instance) {
        CppToken.swap(instance);
    }

  private:

    nostd::unique_ptr<context_api::Token> CppToken;
};
} // namespace libmexclass::opentelemetry
