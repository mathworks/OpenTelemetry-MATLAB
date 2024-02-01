// Copyright 2024 The MathWorks, Inc.

#pragma once

#include <chrono>

#include "MatlabDataArray.hpp"
#include "mex.hpp"

namespace libmexclass::opentelemetry {
struct AsynchronousCallbackInput
{
  AsynchronousCallbackInput(const matlab::data::Array& fh, 
          const std::chrono::milliseconds& timeout, 
          const std::shared_ptr<matlab::engine::MATLABEngine> eng) 
                   : FunctionHandle(fh), Timeout(timeout), MexEngine(eng) {}

  matlab::data::Array FunctionHandle;
  std::chrono::milliseconds Timeout;
  const std::shared_ptr<matlab::engine::MATLABEngine> MexEngine;
};
} // namespace libmexclass::opentelemetry


