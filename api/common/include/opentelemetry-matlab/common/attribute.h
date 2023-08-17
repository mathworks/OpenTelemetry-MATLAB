// Copyright 2023 The MathWorks, Inc.

#pragma once
#include "opentelemetry-matlab/common/ProcessedAttributes.h"

#include "opentelemetry/common/attribute_value.h"
#include "opentelemetry/nostd/string_view.h"

#include "MatlabDataArray.hpp"

#include <list>

namespace common = opentelemetry::common;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {

void processAttribute(const std::string& attrname, 			// input, attribute name
		const matlab::data::Array& attrvalue, 			// input, unprocessed attribute value 
		ProcessedAttributes& attrs);                            // output, processed attributes struct

} // namespace libmexclass::opentelemetry
