// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/trace/SimpleSpanProcessorProxy.h"

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult SimpleSpanProcessorProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
    libmexclass::proxy::ID exporterid = exporterid_mda[0];
    std::shared_ptr<SpanExporterProxy> exporter = std::static_pointer_cast<SpanExporterProxy>(
        libmexclass::proxy::ProxyManager::getProxy(exporterid));
    return std::make_shared<SimpleSpanProcessorProxy>(exporter);
}
} // namespace libmexclass::opentelemetry

