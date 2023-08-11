// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/metrics/CounterProxy.h"

#include "libmexclass/proxy/ProxyManager.h"


#include "MatlabDataArray.hpp"

#include <chrono>

namespace libmexclass::opentelemetry {


void CounterProxy::add(libmexclass::proxy::method::Context& context){
  
    matlab::data::Array value_mda = context.inputs[0];
    double value = static_cast<double>(value_mda[0]);
    CppCounter->Add(value);
    
}



} // namespace libmexclass::opentelemetry
