// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/trace/SpanProxy.h"
#include "opentelemetry-matlab/trace/ScopeProxy.h"
#include "opentelemetry-matlab/trace/SpanContextProxy.h"
#include "opentelemetry-matlab/trace/attribute.h"

#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/trace/scope.h"
#include "opentelemetry/trace/span_metadata.h"
#include "opentelemetry/trace/span_startoptions.h"

#include <assert.h>
#include <chrono>

namespace common = opentelemetry::common;

namespace libmexclass::opentelemetry {
void SpanProxy::endSpan(libmexclass::proxy::method::Context& context) {
    // TODO One input case uses steady_time which has an epoch that is not fixed
    /*
    matlab::data::TypedArray<double> endtime_mda = context.inputs[0];
    common::SteadyTimestamp endtime{std::chrono::duration<double>{endtime_mda[0]}};
    trace_api::EndSpanOptions options;
    options.end_steady_time = endtime;
    CppSpan->End(options);
    */
    CppSpan->End();
}

void SpanProxy::makeCurrent(libmexclass::proxy::method::Context& context) {
    // instantiate a ScopeProxy instance
    auto scproxy = std::shared_ptr<libmexclass::proxy::Proxy>(new ScopeProxy{CppSpan});
    
    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(scproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}

void SpanProxy::updateName(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray name_mda = context.inputs[0];
    std::string name = static_cast<std::string>(name_mda[0]);

    CppSpan->UpdateName(name);
}

void SpanProxy::setAttribute(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray attrname_mda = context.inputs[0];
    std::string attrname = static_cast<std::string>(attrname_mda[0]);
    matlab::data::Array attrvalue = context.inputs[1];

    std::vector<std::pair<std::string, common::AttributeValue> > spanattrs;
    std::vector<std::vector<double> > attrdims_double; // vector of vector, to hold the dimensions of array attributes 
   
    processAttribute(attrname, attrvalue, spanattrs, attrdims_double); 
						      
    for (size_t i = 0; i<spanattrs.size(); ++i) {
       CppSpan->SetAttribute(spanattrs[i].first, spanattrs[i].second); 
    }
}

void SpanProxy::addEvent(libmexclass::proxy::method::Context& context) {
    // Expect at least 2 inputs
    matlab::data::StringArray eventname_mda = context.inputs[0];
    std::string eventname = static_cast<std::string>(eventname_mda[0]);
    matlab::data::TypedArray<double> eventtime_mda = context.inputs[1];
    common::SystemTimestamp eventtime{std::chrono::duration<double>{eventtime_mda[0]}};
    size_t nin = context.inputs.getNumberOfElements();
    // attributes
    std::vector<std::pair<std::string, common::AttributeValue> > eventattrs;
    // TODO Use one level of std::vector instead of 2
    std::vector<std::vector<double> > attrdims_double; // vector of vector, to hold the dimensions of array attributes 
    for (size_t i = 2, count = 0; i < nin; i += 2, ++count) {
       matlab::data::StringArray attrname_mda = context.inputs[i];
       std::string attrname = static_cast<std::string>(attrname_mda[0]);
       matlab::data::Array attrvalue = context.inputs[i+1];

       processAttribute(attrname, attrvalue, eventattrs, attrdims_double);
    }
    if (nin < 3) {
       CppSpan->AddEvent(eventname, eventtime);
    } else {
       CppSpan->AddEvent(eventname, eventtime, eventattrs);
    }
}

void SpanProxy::setStatus(libmexclass::proxy::method::Context& context) {
    matlab::data::StringArray status_mda = context.inputs[0];
    std::string status = static_cast<std::string>(status_mda[0]);
    matlab::data::StringArray descr_mda = context.inputs[1];
    std::string descr = static_cast<std::string>(descr_mda[0]);

    trace_api::StatusCode code;
    if (status.compare("Unset")==0) {
       code = trace_api::StatusCode::kUnset;
    } else if (status.compare("Ok")==0) {
       code = trace_api::StatusCode::kOk;
    } else {
       assert(status.compare("Error")==0);
       code = trace_api::StatusCode::kError;
    } 
    CppSpan->SetStatus(code, descr);
}

void SpanProxy::getContext(libmexclass::proxy::method::Context& context) {
    trace_api::SpanContext sc = CppSpan->GetContext();

    // instantiate a ScopeProxy instance
    auto scproxy = std::shared_ptr<libmexclass::proxy::Proxy>(new SpanContextProxy(std::move(sc)));

    // obtain a proxy ID
    libmexclass::proxy::ID proxyid = libmexclass::proxy::ProxyManager::manageProxy(scproxy);

    // return the ID
    matlab::data::ArrayFactory factory;
    auto proxyid_mda = factory.createScalar<libmexclass::proxy::ID>(proxyid);
    context.outputs[0] = proxyid_mda;
}

void SpanProxy::isRecording(libmexclass::proxy::method::Context& context) {
    bool tf = CppSpan->IsRecording();
    
    matlab::data::ArrayFactory factory;
    auto tf_mda = factory.createScalar(tf);
    context.outputs[0] = tf_mda;
}


} // namespace libmexclass::opentelemetry
