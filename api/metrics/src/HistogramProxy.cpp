// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/HistogramProxy.h"

#include "libmexclass/proxy/ProxyManager.h"


#include "MatlabDataArray.hpp"

#include <chrono>

namespace libmexclass::opentelemetry {


void HistogramProxy::record(libmexclass::proxy::method::Context& context){
    // Get value
    matlab::data::Array value_mda = context.inputs[0];
    double value = static_cast<double>(value_mda[0]);
    // Create empty context
    auto ctxt = context_api::Context();
    // If no attributes input, record value and context
    size_t nin = context.inputs.getNumberOfElements();
    if (nin == 1){
        CppHistogram->Record(value, ctxt);
    } 
    // Otherwise, get attributes, record value, attributes and context
    else { 
        ProcessedAttributes attrs;
        matlab::data::StringArray attrnames_mda = context.inputs[1];
        matlab::data::Array attrvalues_mda = context.inputs[2];
        size_t nattrs = attrnames_mda.getNumberOfElements();
        for (size_t i = 0; i < nattrs; i ++){
            std::string attrname = static_cast<std::string>(attrnames_mda[i]);
            matlab::data::Array attrvalue = attrvalues_mda[i];
            processAttribute(attrname, attrvalue, attrs);
        }
        CppHistogram->Record(value, attrs.Attributes, ctxt);
    }
    
}



} // namespace libmexclass::opentelemetry
