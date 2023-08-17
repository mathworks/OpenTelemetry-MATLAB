// Copyright 2023 The MathWorks, Inc.

#include <list>

#include "opentelemetry-matlab/sdk/common/Resource.h"
#include "opentelemetry-matlab/common/attribute.h"

#include "opentelemetry/common/attribute_value.h"
#include "opentelemetry/nostd/string_view.h"

#define OTEL_MATLAB_VERSION "1.2.0"

namespace common = opentelemetry::common;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry::sdk {

resource::Resource createResource(const matlab::data::StringArray& resourcenames_mda, 
		const matlab::data::CellArray& resourcevalues_mda) {
    size_t nresourceattrs = resourcenames_mda.getNumberOfElements();
    ProcessedAttributes resourceattrs;
    for (size_t i = 0; i < nresourceattrs; ++i) {
       std::string resourcename = static_cast<std::string>(resourcenames_mda[i]);
       matlab::data::Array resourcevalue = resourcevalues_mda[i];

       processAttribute(resourcename, resourcevalue, resourceattrs);
    }
    resourceattrs.Attributes.push_back(std::pair<std::string, common::AttributeValue>("telemetry.sdk.language", "MATLAB"));
    resourceattrs.Attributes.push_back(std::pair<std::string, common::AttributeValue>("telemetry.sdk.version", OTEL_MATLAB_VERSION));
    auto resource_custom = resource::Resource::Create(common::KeyValueIterableView{resourceattrs.Attributes});    
    return std::move(resource_custom);
}

} // namespace libmexclass::opentelemetry
