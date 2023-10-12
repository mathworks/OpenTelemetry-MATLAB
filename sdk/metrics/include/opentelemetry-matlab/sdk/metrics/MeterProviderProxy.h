// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Proxy.h"
#include "libmexclass/proxy/method/Context.h"


#include "opentelemetry/exporters/otlp/otlp_http_metric_exporter_factory.h"
#include "opentelemetry/exporters/otlp/otlp_http_metric_exporter.h"
#include "opentelemetry/exporters/otlp/otlp_http_metric_exporter_options.h"
#include "opentelemetry/exporters/otlp/otlp_http_exporter.h"

#include "opentelemetry/metrics/provider.h"
#include "opentelemetry/metrics/meter_provider.h"
#include "opentelemetry/sdk/common/global_log_handler.h"
#include "opentelemetry/sdk/metrics/aggregation/default_aggregation.h"
#include "opentelemetry/sdk/metrics/aggregation/histogram_aggregation.h"
#include "opentelemetry/sdk/metrics/export/periodic_exporting_metric_reader_factory.h"
#include "opentelemetry/sdk/metrics/meter.h"
#include "opentelemetry/sdk/metrics/meter_provider.h"
#include "opentelemetry/sdk/metrics/meter_provider_factory.h"
#include "opentelemetry/sdk/metrics/push_metric_exporter.h"
#include "opentelemetry/sdk/resource/resource.h"


#include "opentelemetry-matlab/metrics/MeterProxy.h"
#include "opentelemetry-matlab/metrics/MeterProviderProxy.h"
#include "opentelemetry-matlab/sdk/common/resource.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;
namespace metrics_sdk = opentelemetry::sdk::metrics;
namespace common          = opentelemetry::common;
namespace otlpexporter = opentelemetry::exporter::otlp;
namespace resource = opentelemetry::sdk::resource;


namespace libmexclass::opentelemetry::sdk {
class MeterProviderProxy : public libmexclass::opentelemetry::MeterProviderProxy {
  public:
    MeterProviderProxy(nostd::shared_ptr<metrics_api::MeterProvider> mp) : libmexclass::opentelemetry::MeterProviderProxy(mp), CppMeterProvider(mp) {
        REGISTER_METHOD(MeterProviderProxy, addMetricReader);
    }

    static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments);

    void addMetricReader(libmexclass::proxy::method::Context& context);

  protected:
    nostd::shared_ptr<metrics_api::MeterProvider> CppMeterProvider;
};
} // namespace libmexclass::opentelemetry
