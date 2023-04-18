// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry/common/attribute_value.h"
#include "opentelemetry/nostd/string_view.h"

#include "MatlabDataArray.hpp"

namespace common = opentelemetry::common;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {

void processAttribute(const std::string& attrname, 			// input, attribute name
		const matlab::data::Array& attrvalue, 			// input, unprocessed attribute value 
		std::list<std::pair<std::string, common::AttributeValue> >& attrs,  // output, processed attribute name-value pair
		std::list<std::string>& string_buffer,			// buffer to store processed string attribute values
									// Buffers are necessary to persist these processed attribute
									// values beyond the scope of this function
									// Lists are used to ensure no memory reallocation as it grows, 
									// which happens with vectors
		std::list<std::vector<nostd::string_view> >& stringview_buffer,     // buffer used only for string array attributes 
		std::list<std::vector<double> >& dimensions_buffer);	// buffer for array dimensions of nonscalar attribute values

} // namespace libmexclass::opentelemetry
