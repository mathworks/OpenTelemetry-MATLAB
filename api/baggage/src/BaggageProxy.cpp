// Copyright 2023 The MathWorks, Inc.

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry-matlab/context/ContextProxy.h"
#include "opentelemetry-matlab/baggage/BaggageProxy.h"

#include "opentelemetry/baggage/baggage.h"
#include "opentelemetry/baggage/baggage_context.h"

#include "MatlabDataArray.hpp"

namespace libmexclass::opentelemetry {

libmexclass::proxy::MakeResult BaggageProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    size_t nin = constructor_arguments.getNumberOfElements();
    nostd::shared_ptr<baggage_api::Baggage> baggage;
    if (nin == 1) {
        matlab::data::TypedArray<uint64_t> contextid_mda = constructor_arguments[0];
        libmexclass::proxy::ID contextid = contextid_mda[0];

	context_api::Context ctxt = std::static_pointer_cast<ContextProxy>(
		libmexclass::proxy::ProxyManager::getProxy(contextid))->getInstance();
	baggage = baggage_api::GetBaggage(ctxt);
    } else {  // 2 inputs
        matlab::data::StringArray keys_mda = constructor_arguments[0];
        matlab::data::StringArray values_mda = constructor_arguments[1];
	size_t nkeys = keys_mda.getNumberOfElements();

        std::list<std::pair<std::string, std::string> > attrs;

	for (size_t i = 0; i < nkeys; ++i) {
            attrs.push_back(std::pair(static_cast<std::string>(keys_mda[i]), 
			static_cast<std::string>(values_mda[i])));
	}

	baggage = nostd::shared_ptr<baggage_api::Baggage>(new baggage_api::Baggage(attrs));
    }
    return std::make_shared<BaggageProxy>(baggage);
}

void BaggageProxy::getAllEntries(libmexclass::proxy::method::Context& context) {
    std::list<std::string> keys;
    std::list<std::string> values;

    // repeatedly invoke the callback lambda to retrieve each entry
    bool success = CppBaggage->GetAllEntries(
        [&keys, &values](nostd::string_view currkey, nostd::string_view currvalue) {
	  keys.push_back(std::string(currkey));
	  values.push_back(std::string(currvalue));

          return true;
        });

    size_t nkeys = keys.size();
    matlab::data::ArrayDimensions dims = {nkeys, 1};
    matlab::data::ArrayFactory factory;
    auto keys_mda = factory.createArray(dims, keys.cbegin(), keys.cend());
    auto values_mda = factory.createArray(dims, values.cbegin(), values.cend());
    context.outputs[0] = keys_mda;
    context.outputs[1] = values_mda;
}

void BaggageProxy::setEntries(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray keys_mda = context.inputs[0];
    matlab::data::StringArray values_mda = context.inputs[1];
    size_t nkeys = keys_mda.getNumberOfElements();
    for (size_t i = 0; i < nkeys; ++i) {
        CppBaggage = CppBaggage->Set(static_cast<std::string>(keys_mda[i]), 
			static_cast<std::string>(values_mda[i]));
    }
}

void BaggageProxy::deleteEntries(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray keys_mda = context.inputs[0];
    for (auto key : keys_mda) {
        CppBaggage = CppBaggage->Delete(static_cast<std::string>(key));
    }
}

void BaggageProxy::insertBaggage(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> contextid_mda = context.inputs[0];
    libmexclass::proxy::ID contextid = contextid_mda[0];
    context_api::Context ctxt = std::static_pointer_cast<ContextProxy>(
		libmexclass::proxy::ProxyManager::getProxy(contextid))->getInstance();
    context_api::Context newctxt = baggage_api::SetBaggage(ctxt, CppBaggage);

    auto ctxtproxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ContextProxy(newctxt));

    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(ctxtproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}

} // namespace libmexclass::opentelemetry
