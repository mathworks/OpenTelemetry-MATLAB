// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"

#define OTEL_MATLAB_VERSION "0.1.0"

namespace libmexclass::opentelemetry::sdk {
class TracerProviderProxy : public libmexclass::opentelemetry::TracerProviderProxy {
  public:
    TracerProviderProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments);
};
} // namespace libmexclass::opentelemetry
