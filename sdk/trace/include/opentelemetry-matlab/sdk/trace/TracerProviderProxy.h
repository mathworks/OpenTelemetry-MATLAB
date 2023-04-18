// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry-matlab/trace/TracerProviderProxy.h"

namespace libmexclass::opentelemetry::sdk {
class TracerProviderProxy : public libmexclass::opentelemetry::TracerProviderProxy {
  public:
    TracerProviderProxy(const libmexclass::proxy::FunctionArguments& constructor_arguments);
};
} // namespace libmexclass::opentelemetry
