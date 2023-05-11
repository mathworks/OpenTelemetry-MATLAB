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
    // zero input supports the code path for empty context creation
    // one input supports the code path for getCurrentContext
    ContextProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments) 
	    : CppContext(constructor_arguments.isEmpty()? context_api::Context() : context_api::RuntimeContext::GetCurrent())
    {
        registerMethods();
    }

    ContextProxy(context_api::Context ctxt) : CppContext{ctxt} {
        registerMethods();
    }

    context_api::Context getInstance() {
        return CppContext;
    }

    void setCurrentContext(libmexclass::proxy::method::Context& context);

  private:
    void registerMethods() {
        REGISTER_METHOD(ContextProxy, setCurrentContext);
    }

    context_api::Context CppContext;
};
} // namespace libmexclass::opentelemetry
