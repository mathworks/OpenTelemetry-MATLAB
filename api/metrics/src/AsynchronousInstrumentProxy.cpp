// Copyright 2023-2024 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/AsynchronousInstrumentProxy.h"
#include "opentelemetry-matlab/metrics/MeasurementFetcher.h"

#include "MatlabDataArray.hpp"
#include <algorithm>

namespace libmexclass::opentelemetry {


void AsynchronousInstrumentProxy::addCallback(libmexclass::proxy::method::Context& context){
    addCallback_helper(context.inputs[0]);
}

void AsynchronousInstrumentProxy::addCallback_helper(const matlab::data::Array& callback){
    CallbackFunctions.push_back(callback);
    CppInstrument->AddCallback(MeasurementFetcher::Fetcher, static_cast<void*>(&CallbackFunctions.back()));
}

void AsynchronousInstrumentProxy::removeCallback(libmexclass::proxy::method::Context& context){
    matlab::data::Array callback_mda = context.inputs[0];
    matlab::data::TypedArray<double> idx_mda = context.inputs[1];
    double idx = idx_mda[0] - 1;   // adjust index from 1-based in MATLAB to 0-based in C++
    auto iter = CallbackFunctions.begin();
    std::advance(iter, idx);
    CallbackFunctions.erase(iter);
    CppInstrument->RemoveCallback(MeasurementFetcher::Fetcher, static_cast<void*>(&(*iter)));
}

} // namespace libmexclass::opentelemetry
