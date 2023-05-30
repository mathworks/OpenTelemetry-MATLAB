// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/context/propagation/CompositePropagatorProxy.h"

#include "opentelemetry/context/propagation/composite_propagator.h"

#include "libmexclass/proxy/ProxyManager.h"

namespace context_propagation = opentelemetry::context::propagation;

namespace libmexclass::opentelemetry {
CompositePropagatorProxy::CompositePropagatorProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments)
{
    matlab::data::TypedArray<uint64_t> propagatorid_mda = constructor_arguments[0];
    size_t npropagators = propagatorid_mda.getNumberOfElements();
    std::vector<std::unique_ptr<context_propagation::TextMapPropagator> > propagators;
    propagators.reserve(npropagators);
	
    for (auto propagatorid : propagatorid_mda) {
        propagators.push_back(std::static_pointer_cast<TextMapPropagatorProxy>(
		   libmexclass::proxy::ProxyManager::getProxy(propagatorid))->getUniquePtrCopy());
    }

    CppPropagator = nostd::shared_ptr<context_propagation::TextMapPropagator>(new context_propagation::CompositePropagator(std::move(propagators)));
}
} // namespace libmexclass::opentelemetry
