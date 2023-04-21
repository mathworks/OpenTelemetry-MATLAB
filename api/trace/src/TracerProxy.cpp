// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/trace/TracerProxy.h"
#include "opentelemetry-matlab/trace/SpanProxy.h"
#include "opentelemetry-matlab/trace/SpanContextProxy.h"
#include "opentelemetry-matlab/trace/attribute.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "MatlabDataArray.hpp"

namespace libmexclass::opentelemetry {
void TracerProxy::startSpan(libmexclass::proxy::method::Context& context) {
    size_t ninputs = context.inputs.getNumberOfElements();
    const size_t nfixedinputs = 5;
    assert(ninputs >= nfixedinputs && (ninputs - nfixedinputs) % 3 == 0);  // each link uses 3 inputs
						     
    matlab::data::StringArray name_mda = context.inputs[0];
    std::string name = static_cast<std::string>(name_mda[0]);
    matlab::data::TypedArray<uint64_t> parentid_mda = context.inputs[1];
    libmexclass::proxy::ID parentid = parentid_mda[0];
    libmexclass::proxy::ID noparentid(-1);   // wrap around to intmax
    matlab::data::StringArray kind_mda = context.inputs[2];
    std::string kindstr = static_cast<std::string>(kind_mda[0]);
    matlab::data::StringArray attrnames_mda = context.inputs[3];
    matlab::data::Array attrnames_base_mda = context.inputs[3];
    size_t nattrs = attrnames_base_mda.getNumberOfElements();
    matlab::data::CellArray attrvalues_mda = context.inputs[4];
    
    trace_api::StartSpanOptions options;

    // populate the parent field if supplied
    // parent
    if (parentid != noparentid) {
       options.parent = std::static_pointer_cast<SpanContextProxy>(
		       libmexclass::proxy::ProxyManager::getProxy(parentid))->getInstance();
    }
    // kind
    trace_api::SpanKind kind;
    if (kindstr.compare("internal")==0) {
       kind = trace_api::SpanKind::kInternal;
    } else if (kindstr.compare("server")==0) {
       kind = trace_api::SpanKind::kServer;
    } else if (kindstr.compare("client")==0) {
       kind = trace_api::SpanKind::kClient;
    } else if (kindstr.compare("producer")==0) {
       kind = trace_api::SpanKind::kProducer;
    } else {
       assert(kindstr.compare("consumer")==0);
       kind = trace_api::SpanKind::kConsumer;
    } 
    options.kind = kind;

    // attributes
    std::list<std::pair<std::string, common::AttributeValue> > attrs;
    std::list<std::vector<double> > attrdims_double; // list of vectors, to hold the dimensions of array attributes 
    std::list<std::string> stringattrs; // list of strings as a buffer to hold the string attributes
    std::list<std::vector<nostd::string_view> > stringviews; // list of vector of strings views, used for string array attributes only
    for (size_t i = 0; i < nattrs; ++i) {
       std::string attrname = static_cast<std::string>(attrnames_mda[i]);
       matlab::data::Array attrvalue = attrvalues_mda[i];

       processAttribute(attrname, attrvalue, attrs, stringattrs, stringviews, attrdims_double);
    }

    // links
    std::list<std::pair<trace_api::SpanContext, std::list<std::pair<std::string, common::AttributeValue> > > > links;
    for (size_t i = nfixedinputs; i < ninputs; i+=3) {
       // link target
       matlab::data::TypedArray<uint64_t> linktargetid_mda = context.inputs[i];
       libmexclass::proxy::ID linktargetid = linktargetid_mda[0];
       std::shared_ptr<SpanContextProxy> linktarget = std::static_pointer_cast<SpanContextProxy>(
		       libmexclass::proxy::ProxyManager::getProxy(linktargetid));

       // link attributes
       std::list<std::pair<std::string, common::AttributeValue> > linkattrs;
       matlab::data::StringArray linkattrnames_mda = context.inputs[i+1];
       matlab::data::Array linkattrnames_base_mda = context.inputs[i+1];
       size_t nlinkattrs = linkattrnames_base_mda.getNumberOfElements();
       matlab::data::Array linkattrvalues_mda = context.inputs[i+2];
       for (size_t ii = 0; ii < nlinkattrs; ++ii) {
          std::string linkattrname = static_cast<std::string>(linkattrnames_mda[ii]);
          matlab::data::Array linkattrvalue = linkattrvalues_mda[ii];
  
          processAttribute(linkattrname, linkattrvalue, linkattrs, stringattrs, stringviews, attrdims_double);
       }
       links.push_back(std::pair(linktarget->getInstance(), linkattrs));
    }

    auto sp = CppTracer->StartSpan(name, attrs, links, options);

    // instantiate a SpanProxy instance
    SpanProxy* newproxy = new SpanProxy(libmexclass::proxy::FunctionArguments());
    newproxy->setInstance(sp);
    auto spproxy = std::shared_ptr<libmexclass::proxy::Proxy>(newproxy);
    
    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(spproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}
} // namespace libmexclass::opentelemetry
