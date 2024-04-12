// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/logs/LoggerProxy.h"
#include "opentelemetry-matlab/common/attribute.h"
#include "opentelemetry-matlab/context/ContextProxy.h"
#include "libmexclass/proxy/ProxyManager.h"

#include "opentelemetry/logs/severity.h"
#include "opentelemetry/logs/log_record.h"
#include "opentelemetry/trace/context.h"
#include "opentelemetry/context/context.h"

#include "MatlabDataArray.hpp"

namespace logs_api = opentelemetry::logs;
namespace trace_api = opentelemetry::trace;
namespace context_api = opentelemetry::context;
namespace common = opentelemetry::common;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
void LoggerProxy::emitLogRecord(libmexclass::proxy::method::Context& context) {
    matlab::data::TypedArray<double> severity_mda = context.inputs[0];
    int severity = static_cast<int>(severity_mda[0]);
    matlab::data::Array body_mda = context.inputs[1];
    matlab::data::TypedArray<uint64_t> contextid_mda = context.inputs[2];
    libmexclass::proxy::ID contextid = contextid_mda[0];
    libmexclass::proxy::ID nocontextid(-1);   // wrap around to intmax
    matlab::data::TypedArray<double> timestamp_mda = context.inputs[3];
    double timestamp = timestamp_mda[0];    // number of seconds since 1/1/1970 (i.e. POSIX time)
    matlab::data::StringArray attrnames_mda = context.inputs[4];
    size_t nattrs = attrnames_mda.getNumberOfElements();
    matlab::data::CellArray attrvalues_mda = context.inputs[5];
    
    // log body
    ProcessedAttributes bodyattrs;
    processAttribute("Body", body_mda, bodyattrs);  
    common::AttributeValue log_body;
    if (bodyattrs.Attributes.empty()) {
        log_body = "";   // invalid body
    } else {
        log_body = bodyattrs.Attributes.front().second;
    }
    // if body is nonscalar, bodyattrs.Attribute will contain an additional element 
    // which is the array size
    bool array_body = (bodyattrs.Attributes.size() > 1);  

    nostd::unique_ptr<logs_api::LogRecord> rec = CppLogger->CreateLogRecord();

    // context
    if (contextid != nocontextid) {
        context_api::Context supplied_context = std::static_pointer_cast<ContextProxy>(
	       libmexclass::proxy::ProxyManager::getProxy(contextid))->getInstance();
        trace_api::SpanContext sc = trace_api::GetSpan(supplied_context)->GetContext();
	rec->SetTraceId(sc.trace_id());
	rec->SetSpanId(sc.span_id());
	rec->SetTraceFlags(sc.trace_flags());
    }

    // timestamp
    if (timestamp == timestamp) { // not NaN. NaN means not specified
       rec->SetTimestamp(common::SystemTimestamp{std::chrono::duration<double>(timestamp)});
    }

    // attributes
    ProcessedAttributes attrs;
    if (nattrs > 0) {
       for (size_t i = 0; i < nattrs; ++i) {
          std::string attrname = static_cast<std::string>(attrnames_mda[i]);
          matlab::data::Array attrvalue = attrvalues_mda[i];

          processAttribute(attrname, attrvalue, attrs);
       }
       auto record_attribute = [&](const std::pair<std::string, common::AttributeValue> attr) 
           {rec->SetAttribute(attr.first, attr.second);};
       std::for_each(attrs.Attributes.cbegin(), attrs.Attributes.cend(), record_attribute);
    }
    // Add size attribute if body is nonscalar
    if (array_body) {
       rec->SetAttribute(bodyattrs.Attributes.back().first, bodyattrs.Attributes.back().second);
    }

    CppLogger->EmitLogRecord(std::move(rec), static_cast<logs_api::Severity>(severity), log_body);
}
} // namespace libmexclass::opentelemetry
