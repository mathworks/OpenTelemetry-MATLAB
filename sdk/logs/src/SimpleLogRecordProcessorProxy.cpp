// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/logs/SimpleLogRecordProcessorProxy.h"

namespace libmexclass::opentelemetry::sdk {
libmexclass::proxy::MakeResult SimpleLogRecordProcessorProxy::make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
    matlab::data::TypedArray<uint64_t> exporterid_mda = constructor_arguments[0];
    libmexclass::proxy::ID exporterid = exporterid_mda[0];
    std::shared_ptr<LogRecordExporterProxy> exporter = std::static_pointer_cast<LogRecordExporterProxy>(
        libmexclass::proxy::ProxyManager::getProxy(exporterid));
    return std::make_shared<SimpleLogRecordProcessorProxy>(exporter);
}
} // namespace libmexclass::opentelemetry

