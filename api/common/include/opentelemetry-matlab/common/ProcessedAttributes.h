// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry/common/attribute_value.h"
#include "opentelemetry/nostd/string_view.h"

#include <list>

namespace common = opentelemetry::common;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {

struct ProcessedAttributes {
    std::list<std::pair<std::string, common::AttributeValue> > Attributes;
    std::list<std::vector<double> > DimensionsBuffer; // list of vector, to hold the dimensions of array attributes 
    std::list<std::string> StringBuffer; // list of strings as a buffer to hold the string attributes
    std::list<std::vector<nostd::string_view> > StringViewBuffer; // list of vector of strings views, used for string array attributes only
};
} // namespace libmexclass::opentelemetry
