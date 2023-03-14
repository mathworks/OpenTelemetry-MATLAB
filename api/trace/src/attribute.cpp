// Copyright 2023 The MathWorks, Inc.


#include "opentelemetry-matlab/trace/attribute.h"

#include "opentelemetry/nostd/span.h"

namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {

void processAttribute(std::string& attrname, const matlab::data::Array& attrvalue, 
		std::vector<std::pair<std::string, common::AttributeValue> >& attrs, 
		std::vector<std::vector<double> >& attrvalue_dims_buffer_vector) {

    std::vector<double> attrvalue_dims_buffer; // dimensions of array attribute, cast to double

    matlab::data::ArrayType valtype = attrvalue.getType();
    matlab::data::ArrayDimensions attrdims = attrvalue.getDimensions();

    // TODO Consider using templates instead of a giant switchyard
    if (matlab::data::getNumElements(attrdims) == 1) { // scalar case
       if (valtype == matlab::data::ArrayType::DOUBLE) {
          matlab::data::TypedArray<double> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, attrvalue_mda[0]));
       } else if (valtype == matlab::data::ArrayType::INT32) {
          matlab::data::TypedArray<int32_t> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, attrvalue_mda[0]));
       } else if (valtype == matlab::data::ArrayType::UINT32) {
          matlab::data::TypedArray<uint32_t> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, attrvalue_mda[0]));
       } else if (valtype == matlab::data::ArrayType::INT64) {
          matlab::data::TypedArray<int64_t> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, attrvalue_mda[0]));
       } else if (valtype == matlab::data::ArrayType::LOGICAL) {
          matlab::data::TypedArray<bool> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, attrvalue_mda[0]));
       } else {   // string
          matlab::data::StringArray attrvalue_mda = attrvalue;
	  std::string attrvalue_string{static_cast<std::string>(attrvalue_mda[0])};
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, attrvalue_string));
       }
    } else {  // array case
       if (valtype == matlab::data::ArrayType::DOUBLE) {
          matlab::data::TypedArray<double> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, 
	     nostd::span<const double>{&(*attrvalue_mda.cbegin()), &(*attrvalue_mda.cend())})); 
       } else if (valtype == matlab::data::ArrayType::INT32) {
          matlab::data::TypedArray<int32_t> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, 
	     nostd::span<const int32_t>{&(*attrvalue_mda.cbegin()), &(*attrvalue_mda.cend())})); 
       } else if (valtype == matlab::data::ArrayType::UINT32) {
          matlab::data::TypedArray<uint32_t> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, 
	     nostd::span<const uint32_t>{&(*attrvalue_mda.cbegin()), &(*attrvalue_mda.cend())})); 
       } else if (valtype == matlab::data::ArrayType::INT64) {
          matlab::data::TypedArray<int64_t> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, 
	     nostd::span<const int64_t>{&(*attrvalue_mda.cbegin()), &(*attrvalue_mda.cend())})); 
       } else if (valtype == matlab::data::ArrayType::LOGICAL) {
          matlab::data::TypedArray<bool> attrvalue_mda = attrvalue;
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, 
	     nostd::span<const bool>{&(*attrvalue_mda.cbegin()), &(*attrvalue_mda.cend())})); 
       } else {   // string
          // TODO String arrays
       }
       // Add a size attribute to preserve the shape
       std::string& sizeattr{attrname.append(".size")};
       // std::vector<double> attrdims_local;
       matlab::data::ArrayDimensions::iterator copyfrom;
       for (copyfrom = attrdims.begin(); copyfrom != attrdims.end(); ++copyfrom) {
          attrvalue_dims_buffer.push_back(static_cast<double>(*copyfrom));
       }
       attrvalue_dims_buffer_vector.push_back(attrvalue_dims_buffer);
       attrs.push_back(std::pair<std::string, common::AttributeValue>(sizeattr, 
	  nostd::span<const double>{&(*attrvalue_dims_buffer_vector.back().cbegin()), 
	  &(*attrvalue_dims_buffer_vector.back().cend())})); 
    }
}
} // namespace
