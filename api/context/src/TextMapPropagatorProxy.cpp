// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/context/propagation/TextMapPropagatorProxy.h"
#include "opentelemetry-matlab/context/propagation/TextMapCarrierProxy.h"
#include "opentelemetry-matlab/context/ContextProxy.h"

#include "opentelemetry/context/context.h"

#include "libmexclass/proxy/ProxyManager.h"

namespace context_api = opentelemetry::context;

namespace libmexclass::opentelemetry {
void TextMapPropagatorProxy::extract(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> carrierid_mda = context.inputs[0];
    libmexclass::proxy::ID carrierid = carrierid_mda[0];
    matlab::data::TypedArray<uint64_t> contextid_mda = context.inputs[1];
    libmexclass::proxy::ID contextid = contextid_mda[0];

    auto carrier = std::static_pointer_cast<TextMapCarrierProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(carrierid))->getInstance();
    auto inputcontext = std::static_pointer_cast<ContextProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(contextid))->getInstance();
    context_api::Context newcontext = CppPropagator->Extract(carrier, inputcontext);

    // instantiate a ContextProxy instance
    ContextProxy* newproxy = new ContextProxy(newcontext);
    auto ctxtproxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(ctxtproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}

void TextMapPropagatorProxy::inject(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> carrierid_mda = context.inputs[0];
    libmexclass::proxy::ID carrierid = carrierid_mda[0];
    matlab::data::TypedArray<uint64_t> contextid_mda = context.inputs[1];
    libmexclass::proxy::ID contextid = contextid_mda[0];

    HttpTextMapCarrier carrier = std::static_pointer_cast<TextMapCarrierProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(carrierid))->getInstance();
    auto inputcontext = std::static_pointer_cast<ContextProxy>(
		    libmexclass::proxy::ProxyManager::getProxy(contextid))->getInstance();
    
    // create a copy of the carrier for the output
    HttpTextMapCarrier carriercopy(carrier); 
    CppPropagator->Inject(carriercopy, inputcontext);
    
    // instantiate a TextMapCarrierProxy instance
    auto carrierproxy = std::shared_ptr<libmexclass::proxy::Proxy>(new TextMapCarrierProxy(carriercopy));
    
    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(carrierproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}
} // namespace libmexclass::opentelemetry
