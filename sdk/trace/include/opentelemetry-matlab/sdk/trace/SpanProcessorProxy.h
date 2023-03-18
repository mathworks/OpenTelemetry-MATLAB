// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/sdk/trace/processor.h"

namespace trace_sdk = opentelemetry::sdk::trace;

namespace libmexclass::opentelemetry::sdk {
class SpanProcessorProxy : public libmexclass::proxy::Proxy {
  public:
    virtual std::unique_ptr<trace_sdk::SpanProcessor> getInstance() = 0;
};
} // namespace libmexclass::opentelemetry
