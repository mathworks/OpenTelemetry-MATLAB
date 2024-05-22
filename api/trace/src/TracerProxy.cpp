// Copyright 2023-2024 The MathWorks, Inc.

#include "opentelemetry-matlab/trace/TracerProxy.h"
#include "opentelemetry-matlab/trace/SpanProxy.h"
#include "opentelemetry-matlab/trace/SpanContextProxy.h"
#include "opentelemetry-matlab/common/attribute.h"
#include "opentelemetry-matlab/context/ContextProxy.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "MatlabDataArray.hpp"

#include <chrono>

namespace libmexclass::opentelemetry {
const libmexclass::proxy::ID NOPARENTID(-1);   // wrap around to intmax
						   
// Helper function to create a span proxy from a otel-cpp Span object
matlab::data::TypedArray<libmexclass::proxy::ID> createSpanProxy(
		nostd::shared_ptr<trace_api::Span> sp) {
   auto spproxy = std::shared_ptr<libmexclass::proxy::Proxy>(new SpanProxy(sp));
    
    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(spproxy);

    // return the ID
    matlab::data::ArrayFactory factory;

    return factory.createScalar<libmexclass::proxy::ID>(proxyid);
}

// startSpan with only span name and no optional inputs
void TracerProxy::startSpanWithNameOnly(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray name_mda = context.inputs[0];
    std::string name = static_cast<std::string>(name_mda[0]);
    auto sp = CppTracer->StartSpan(name);
    context.outputs[0] = createSpanProxy(sp);
}

// Helper function to process parent ID, span kind, and start time inputs, and return an options object
trace_api::StartSpanOptions processOptions(libmexclass::proxy::ID parentid, 
		matlab::data::MATLABString kindstr, double starttime) {
    trace_api::StartSpanOptions options;

    // populate the parent field if supplied
    // parent
    if (parentid != NOPARENTID) {
       options.parent = std::static_pointer_cast<ContextProxy>(
	       libmexclass::proxy::ProxyManager::getProxy(parentid))->getInstance();
    }
    // kind
    trace_api::SpanKind kind;
    if (kindstr->compare(u"internal")==0) {
       kind = trace_api::SpanKind::kInternal;
    } else if (kindstr->compare(u"server")==0) {
       kind = trace_api::SpanKind::kServer;
    } else if (kindstr->compare(u"client")==0) {
       kind = trace_api::SpanKind::kClient;
    } else if (kindstr->compare(u"producer")==0) {
       kind = trace_api::SpanKind::kProducer;
    } else {
       assert(kindstr->compare(u"consumer")==0);
       kind = trace_api::SpanKind::kConsumer;
    } 
    options.kind = kind;

    // starttime
    if (starttime == starttime) { // not NaN. NaN means not specified
       options.start_system_time = common::SystemTimestamp{std::chrono::duration<double>(starttime)};
       options.start_steady_time = common::SteadyTimestamp{std::chrono::system_clock::time_point(options.start_system_time) 
	       - std::chrono::system_clock::now() + std::chrono::steady_clock::now()};
    }
    return options;
}

// startSpan implementation with span name and an options object
void TracerProxy::startSpanWithNameAndOptions(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray name_mda = context.inputs[0];
    std::string name = static_cast<std::string>(name_mda[0]);

    matlab::data::TypedArray<uint64_t> parentid_mda = context.inputs[1];
    libmexclass::proxy::ID parentid = parentid_mda[0];
    matlab::data::StringArray kind_mda = context.inputs[2];
    matlab::data::MATLABString kindstr = kind_mda[0];
    matlab::data::TypedArray<double> starttime_mda = context.inputs[3];
    double starttime = starttime_mda[0];    // number of seconds since 1/1/1970 (i.e. POSIX time)

    trace_api::StartSpanOptions options = processOptions(parentid, kindstr, starttime);

    auto sp = CppTracer->StartSpan(name, options);

    context.outputs[0] = createSpanProxy(sp);
}

// Helper function to process attributes
void processAttributes(const matlab::data::StringArray& attrnames_mda, 
		const matlab::data::CellArray& attrvalues_mda, 
		ProcessedAttributes& attrs) {
    const size_t nattrs = attrnames_mda.getNumberOfElements();
    for (size_t i = 0; i < nattrs; ++i) {
       std::string attrname = static_cast<std::string>(attrnames_mda[i]);
       matlab::data::Array attrvalue = attrvalues_mda[i];

       processAttribute(attrname, attrvalue, attrs);
    }
}

// Helper function to process links
std::list<std::pair<trace_api::SpanContext, std::list<std::pair<std::string, common::AttributeValue> > > > processLinks(
		const matlab::data::Array& contextinputs, size_t linkstartindex, ProcessedAttributes& linkattrs) {
    const size_t ninputs = contextinputs.getNumberOfElements();
    std::list<std::pair<trace_api::SpanContext, std::list<std::pair<std::string, common::AttributeValue> > > > links;
    for (size_t i = linkstartindex; i < ninputs; i+=3) {
       // link target
       matlab::data::TypedArray<uint64_t> linktargetid_mda = contextinputs[i];
       libmexclass::proxy::ID linktargetid = linktargetid_mda[0];
       std::shared_ptr<SpanContextProxy> linktarget = std::static_pointer_cast<SpanContextProxy>(
		       libmexclass::proxy::ProxyManager::getProxy(linktargetid));

       // link attributes
       matlab::data::StringArray linkattrnames_mda = contextinputs[i+1];
       const size_t nlinkattrs = linkattrnames_mda.getNumberOfElements();
       matlab::data::Array linkattrvalues_mda = contextinputs[i+2];
       for (size_t ii = 0; ii < nlinkattrs; ++ii) {
          std::string linkattrname = static_cast<std::string>(linkattrnames_mda[ii]);
          matlab::data::Array linkattrvalue = linkattrvalues_mda[ii];
  
          processAttribute(linkattrname, linkattrvalue, linkattrs);
       }
       links.push_back(std::pair(linktarget->getInstance(), linkattrs.Attributes));
    }
    return links;
}

// startSpan implementation with span name, attributes, and links
void TracerProxy::startSpanWithNameAndAttributes(libmexclass::proxy::method::Context& context) {
    const size_t ninputs = context.inputs.getNumberOfElements();
    const size_t nfixedinputs = 3;
    assert(ninputs >= nfixedinputs && (ninputs - nfixedinputs) % 3 == 0);  // each link uses 3 inputs
						     
    matlab::data::StringArray name_mda = context.inputs[0];
    std::string name = static_cast<std::string>(name_mda[0]);

    matlab::data::StringArray attrnames_mda = context.inputs[1];
    matlab::data::CellArray attrvalues_mda = context.inputs[2];

    // attributes
    ProcessedAttributes attrs;
    processAttributes(attrnames_mda, attrvalues_mda, attrs);

    // links
    ProcessedAttributes linkattrs;
    auto links = processLinks(context.inputs, nfixedinputs, linkattrs);

    auto sp = CppTracer->StartSpan(name, attrs.Attributes, links);

    context.outputs[0] = createSpanProxy(sp);
}

// startSpan implementation with span name, attributes, links, and an options object
void TracerProxy::startSpanWithNameOptionsAttributes(libmexclass::proxy::method::Context& context) {
    const size_t ninputs = context.inputs.getNumberOfElements();
    const size_t nfixedinputs = 6;
    assert(ninputs >= nfixedinputs && (ninputs - nfixedinputs) % 3 == 0);  // each link uses 3 inputs
						     
    matlab::data::StringArray name_mda = context.inputs[0];
    std::string name = static_cast<std::string>(name_mda[0]);

    matlab::data::TypedArray<uint64_t> parentid_mda = context.inputs[1];
    libmexclass::proxy::ID parentid = parentid_mda[0];
    matlab::data::StringArray kind_mda = context.inputs[2];
    matlab::data::MATLABString kindstr = kind_mda[0];
    matlab::data::TypedArray<double> starttime_mda = context.inputs[3];
    double starttime = starttime_mda[0];    // number of seconds since 1/1/1970 (i.e. POSIX time)
    matlab::data::StringArray attrnames_mda = context.inputs[4];
    matlab::data::CellArray attrvalues_mda = context.inputs[5];
    
    trace_api::StartSpanOptions options = processOptions(parentid, kindstr, starttime);

    // attributes
    ProcessedAttributes attrs;
    processAttributes(attrnames_mda, attrvalues_mda, attrs);

    // links
    ProcessedAttributes linkattrs;
    auto links = processLinks(context.inputs, nfixedinputs, linkattrs);

    auto sp = CppTracer->StartSpan(name, attrs.Attributes, links, options);

    context.outputs[0] = createSpanProxy(sp);
}
} // namespace libmexclass::opentelemetry
