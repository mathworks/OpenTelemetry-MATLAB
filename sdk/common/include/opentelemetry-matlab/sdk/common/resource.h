// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry/sdk/resource/resource.h"

#include "MatlabDataArray.hpp"

namespace resource = opentelemetry::sdk::resource;

namespace libmexclass::opentelemetry::sdk {

resource::Resource createResource(const matlab::data::StringArray& resourcenames_mda, 
		const matlab::data::CellArray& resourcevalues_mda);

} // namespace libmexclass::opentelemetry
