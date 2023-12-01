// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"
#include "opentelemetry-matlab/metrics/MeasurementFetcher.h"

#include "MatlabDataArray.hpp"
#include <algorithm>

namespace libmexclass::opentelemetry {


void AsynchronousInstrumentProxy::addCallback(libmexclass::proxy::method::Context& context){
    matlab::data::StringArray callback_mda = context.inputs[0];
    std::string callback = static_cast<std::string>(callback_mda[0]); 
    CallbackFunctions.push_back(callback);
    CppInstrument->AddCallback(MeasurementFetcher::Fetcher, static_cast<void*>(&CallbackFunctions.back()));
}


void AsynchronousInstrumentProxy::removeCallback(libmexclass::proxy::method::Context& context){
    matlab::data::StringArray callback_mda = context.inputs[0];
    std::string callback = static_cast<std::string>(callback_mda[0]); 
    auto iter = std::find(CallbackFunctions.begin(), CallbackFunctions.end(), callback);
    if (iter != CallbackFunctions.end()) {  // found a match
	CallbackFunctions.erase(iter);
        CppInstrument->RemoveCallback(MeasurementFetcher::Fetcher, static_cast<void*>(&(*iter)));
    }
}

} // namespace libmexclass::opentelemetry
