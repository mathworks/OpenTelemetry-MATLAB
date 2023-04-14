// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry/common/attribute_value.h"

#include "MatlabDataArray.hpp"

namespace common = opentelemetry::common;

namespace libmexclass::opentelemetry {

void processAttribute(std::string& attrname, const matlab::data::Array& attrvalue, 
		std::vector<std::pair<std::string, common::AttributeValue> >& attrs, 
		std::vector<std::string>& stringattr_buffer_vector,
		std::vector<std::vector<double> >& attrvalue_dims_buffer_vector);

} // namespace libmexclass::opentelemetry
