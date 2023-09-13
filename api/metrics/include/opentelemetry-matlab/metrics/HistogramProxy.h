// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"

#include "opentelemetry/context/context.h"
#include "opentelemetry/metrics/meter.h"
#include "opentelemetry/metrics/sync_instruments.h"

#include "opentelemetry-matlab/common/attribute.h"
#include "opentelemetry-matlab/common/ProcessedAttributes.h"
#include "opentelemetry-matlab/context/ContextProxy.h"

namespace metrics_api = opentelemetry::metrics;
namespace context = opentelemetry::context;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
class HistogramProxy : public libmexclass::proxy::Proxy {
  public:
    HistogramProxy(nostd::shared_ptr<metrics_api::Histogram<double> > hist) : CppHistogram(hist) {
       REGISTER_METHOD(HistogramProxy, record);
    }

    void record(libmexclass::proxy::method::Context& context);

  private:

    nostd::shared_ptr<metrics_api::Histogram<double> > CppHistogram;

}; 
} // namespace libmexclass::opentelemetry


