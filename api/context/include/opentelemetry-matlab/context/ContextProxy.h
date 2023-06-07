// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry-matlab/context/TokenProxy.h"

#include "opentelemetry/context/context.h"
#include "opentelemetry/context/runtime_context.h"

namespace context_api = opentelemetry::context;

namespace libmexclass::opentelemetry {
class ContextProxy : public libmexclass::proxy::Proxy {
  public:
    ContextProxy(context_api::Context ctxt) : CppContext{ctxt} {
        REGISTER_METHOD(ContextProxy, setCurrentContext);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
        // zero input supports the code path for empty context creation
        // one input supports the code path for getCurrentContext
        return std::make_shared<ContextProxy>(constructor_arguments.isEmpty()? 
			context_api::Context() : context_api::RuntimeContext::GetCurrent());
    }

    context_api::Context getInstance() {
        return CppContext;
    }

    void setCurrentContext(libmexclass::proxy::method::Context& context);

  private:

    context_api::Context CppContext;
};
} // namespace libmexclass::opentelemetry
