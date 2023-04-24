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
    matlab::data::TypedArray<double> endtime_mda = context.inputs[0];
    double endtime = endtime_mda[0];    // number of seconds since 1/1/1970 (i.e. POSIX time)
    if (endtime==endtime) {  // not NaN. NaN means not specified
       trace_api::EndSpanOptions options;
       // conversion between system_time and steady_time
       common::SystemTimestamp end_system_time{std::chrono::duration<double>(endtime)};
       options.end_steady_time = common::SteadyTimestamp{std::chrono::system_clock::time_point(end_system_time) 
	       - std::chrono::system_clock::now() + std::chrono::steady_clock::now()};
       CppSpan->End(options);
    } else {
       CppSpan->End();
    }
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

    std::list<std::pair<std::string, common::AttributeValue> > spanattrs;
    std::list<std::string> stringattrs; // list of strings as a buffer to hold the string attributes
    std::list<std::vector<nostd::string_view> > stringviews; // list of vector of strings views, used for string array attributes only
    std::list<std::vector<double> > attrdims_double; // list of vectors, to hold the dimensions of array attributes 
   
    processAttribute(attrname, attrvalue, spanattrs, stringattrs, stringviews, attrdims_double); 
						      
    for (auto itr = spanattrs.cbegin(); itr!=spanattrs.cend(); ++itr) {
       CppSpan->SetAttribute(itr->first, itr->second); 
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
    std::list<std::pair<std::string, common::AttributeValue> > eventattrs;
    std::list<std::vector<double> > attrdims_double; // list of vector, to hold the dimensions of array attributes 
    std::list<std::string> stringattrs; // list of strings as a buffer to hold the string attributes
    std::list<std::vector<nostd::string_view> > stringviews; // list of vector of strings views, used for string array attributes only
    for (size_t i = 2, count = 0; i < nin; i += 2, ++count) {
       matlab::data::StringArray attrname_mda = context.inputs[i];
       std::string attrname = static_cast<std::string>(attrname_mda[0]);
       matlab::data::Array attrvalue = context.inputs[i+1];

       processAttribute(attrname, attrvalue, eventattrs, stringattrs, stringviews, attrdims_double);
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
