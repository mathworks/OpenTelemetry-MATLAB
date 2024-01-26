// Copyright 2024 The MathWorks, Inc.

#pragma once

#include "MatlabDataArray.hpp"
#include "mex.hpp"

namespace libmexclass::opentelemetry {
struct AsynchronousCallbackInput
{
  AsynchronousCallbackInput(const matlab::data::Array& fh, 
          const std::shared_ptr<matlab::engine::MATLABEngine> eng) 
                   : FunctionHandle(fh), MexEngine(eng) {}

  matlab::data::Array FunctionHandle;
  const std::shared_ptr<matlab::engine::MATLABEngine> MexEngine;
};
} // namespace libmexclass::opentelemetry


