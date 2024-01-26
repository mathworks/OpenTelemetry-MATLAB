// Copyright 2023-2024 The MathWorks, Inc.

#pragma once

namespace metrics_api = opentelemetry::metrics;

namespace libmexclass::opentelemetry {
class MeasurementFetcher
{
public:
  static void Fetcher(metrics_api::ObserverResult observer_result, void * /* state */);
};
} // namespace libmexclass::opentelemetry


