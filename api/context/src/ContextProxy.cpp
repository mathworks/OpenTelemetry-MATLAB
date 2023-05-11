// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/context/ContextProxy.h"

namespace libmexclass::opentelemetry {
void ContextProxy::setCurrentContext(libmexclass::proxy::method::Context& context) {
    auto token = context_api::RuntimeContext::Attach(CppContext); 

    // instantiate TokenProxy instance
    TokenProxy* newproxy = new TokenProxy(libmexclass::proxy::FunctionArguments());
    newproxy->setInstance(token);
    auto tokenproxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);

    // obtain proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(tokenproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}

} // namespace libmexclass::opentelemetry
