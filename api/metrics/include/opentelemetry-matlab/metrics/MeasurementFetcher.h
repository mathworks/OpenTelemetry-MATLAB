// Copyright 2023 The MathWorks, Inc.

#pragma once

namespace metrics_api = opentelemetry::metrics;

namespace libmexclass::opentelemetry {
class MeasurementFetcher
{
public:
  __declspec(dllexport) static void Fetcher(metrics_api::ObserverResult observer_result, void * /* state */);
  static std::shared_ptr<matlab::engine::MATLABEngine> mlptr;
};
} // namespace libmexclass::opentelemetry


