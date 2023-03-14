// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/trace/SpanContextProxy.h"

#include "libmexclass/proxy/ProxyManager.h"

namespace common = opentelemetry::common;

namespace libmexclass::opentelemetry {
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

} // namespace libmexclass::opentelemetry
