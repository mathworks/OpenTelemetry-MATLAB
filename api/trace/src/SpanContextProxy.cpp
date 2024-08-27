// Copyright 2023-2024 The MathWorks, Inc.

#include "opentelemetry-matlab/trace/SpanContextProxy.h"
#include "opentelemetry-matlab/trace/ScopeProxy.h"
#include "opentelemetry-matlab/context/ContextProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/trace/default_span.h"
#include "opentelemetry/trace/context.h"
#include "opentelemetry/trace/trace_flags.h"
#include "opentelemetry/trace/trace_state.h"

#include <list>

namespace common = opentelemetry::common;
namespace context_api = opentelemetry::context;

namespace libmexclass::opentelemetry {

libmexclass::proxy::MakeResult SpanContextProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint8_t> traceid_mda = constructor_arguments[0];
    trace_api::TraceId traceid(nostd::span<const uint8_t, trace_api::TraceId::kSize>(&(*traceid_mda.cbegin()), 16));
    matlab::data::TypedArray<uint8_t> spanid_mda = constructor_arguments[1];
    trace_api::SpanId spanid{nostd::span<const uint8_t, trace_api::SpanId::kSize>(&(*spanid_mda.cbegin()), 8)};
    matlab::data::TypedArray<bool> issampled_mda = constructor_arguments[2];
    bool issampled = issampled_mda[0];
    matlab::data::TypedArray<bool> isremote_mda = constructor_arguments[3];
    bool isremote = isremote_mda[0];

    uint8_t traceflags = 0;
    if (issampled) {
        traceflags |= trace_api::TraceFlags::kIsSampled;
    }
    
    if (constructor_arguments.getNumberOfElements() <= 4) {
        return std::make_shared<SpanContextProxy>(trace_api::SpanContext{traceid, spanid, trace_api::TraceFlags(traceflags), isremote});
    } else {
	auto tracestate = trace_api::TraceState::GetDefault();
	matlab::data::StringArray tracestatekeys_mda = constructor_arguments[4];
	matlab::data::StringArray tracestatevalues_mda = constructor_arguments[5];
	size_t ntskeys = tracestatekeys_mda.getNumberOfElements();
	for (size_t i = 0; i < ntskeys; ++i) {
	    std::string tracestatekeyi = static_cast<std::string>(tracestatekeys_mda[i]), 
		    tracestatevaluei = static_cast<std::string>(tracestatevalues_mda[i]);
	    if (tracestate->IsValidKey(tracestatekeyi) && tracestate->IsValidValue(tracestatevaluei)) {
                tracestate = tracestate->Set(tracestatekeyi, tracestatevaluei);
	    }
	}
        return std::make_shared<SpanContextProxy>(trace_api::SpanContext{traceid, spanid, trace_api::TraceFlags(traceflags), isremote, tracestate});
    }
}

void SpanContextProxy::getTraceId(libmexclass::proxy::method::Context& context) {
    const trace_api::TraceId& tid = CppSpanContext.trace_id();

    // construct a buffer
    constexpr size_t idlen = 2 * trace_api::TraceId::kSize;
    std::string tidstring;
    tidstring.reserve(idlen);
    for (size_t i=0; i<idlen; ++i) {
        tidstring.push_back('0');
    }

    // populate the buffer
    tid.ToLowerBase16(nostd::span<char,idlen>{&(tidstring.front()),idlen});

    matlab::data::ArrayFactory factory;
    auto tid_mda = factory.createScalar(tidstring);
    context.outputs[0] = tid_mda;
}

void SpanContextProxy::getSpanId(libmexclass::proxy::method::Context& context) {
    const trace_api::SpanId& sid = CppSpanContext.span_id();

    // construct a buffer
    constexpr size_t idlen = 2 * trace_api::SpanId::kSize;
    std::string sidstring;
    sidstring.reserve(idlen);
    for (size_t i=0; i<idlen; ++i) {
        sidstring.push_back('0');
    }

    // populate the buffer
    sid.ToLowerBase16(nostd::span<char,idlen>{&(sidstring.front()),idlen});

    matlab::data::ArrayFactory factory;
    auto sid_mda = factory.createScalar(sidstring);
    context.outputs[0] = sid_mda;
}

void SpanContextProxy::getTraceState(libmexclass::proxy::method::Context& context) {
    std::list<std::string> keys;
    std::list<std::string> values;

    // repeatedly invoke the callback lambda to retrieve each entry
    bool success = CppSpanContext.trace_state()->GetAllEntries(
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

void SpanContextProxy::getTraceFlags(libmexclass::proxy::method::Context& context) {
    const trace_api::TraceFlags& traceflags = CppSpanContext.trace_flags();

    // construct a buffer
    constexpr size_t flagslen = 2;
    std::string flagsstring;
    flagsstring.reserve(flagslen);
    for (size_t i=0; i<flagslen; ++i) {
        flagsstring.push_back('0');
    }

    // populate the buffer
    traceflags.ToLowerBase16(nostd::span<char,flagslen>{&(flagsstring.front()),flagslen});

    matlab::data::ArrayFactory factory;
    auto flags_mda = factory.createScalar(flagsstring);
    context.outputs[0] = flags_mda;
}

void SpanContextProxy::isSampled(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;
    auto sampled_mda = factory.createScalar(CppSpanContext.IsSampled());
    context.outputs[0] = sampled_mda;
}

void SpanContextProxy::isValid(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;
    auto valid_mda = factory.createScalar(CppSpanContext.IsValid());
    context.outputs[0] = valid_mda;
}

void SpanContextProxy::isRemote(libmexclass::proxy::method::Context& context) {
    matlab::data::ArrayFactory factory;
    auto remote_mda = factory.createScalar(CppSpanContext.IsRemote());
    context.outputs[0] = remote_mda;
}

void SpanContextProxy::makeCurrent(libmexclass::proxy::method::Context& context) {
    // create a default span to associate with span context
    auto cppspan = nostd::shared_ptr<trace_api::Span>(new trace_api::DefaultSpan(CppSpanContext));

    // instantiate a ScopeProxy instance
    auto scproxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ScopeProxy{cppspan});
    
    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(scproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}

void SpanContextProxy::insertSpan(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<uint64_t> contextid_mda = context.inputs[0];
    libmexclass::proxy::ID contextid = contextid_mda[0];

    // create a default span to associate with span context
    auto cppspan = nostd::shared_ptr<trace_api::Span>(new trace_api::DefaultSpan(CppSpanContext));

    context_api::Context ctxt = std::static_pointer_cast<ContextProxy>(
         libmexclass::proxy::ProxyManager::getProxy(contextid))->getInstance();
    context_api::Context newctxt = trace_api::SetSpan(ctxt, cppspan);
    
    // instantiate a ContextProxy instance
    auto ctxtproxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ContextProxy(std::move(newctxt)));

    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(ctxtproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}

} // namespace libmexclass::opentelemetry
