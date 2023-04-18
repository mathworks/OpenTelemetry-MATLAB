// Copyright 2023 The MathWorks, Inc.


#include "opentelemetry-matlab/trace/attribute.h"

#include "opentelemetry/nostd/span.h"

namespace libmexclass::opentelemetry {

void processAttribute(const std::string& attrname, 			// input, attribute name
		const matlab::data::Array& attrvalue,			// input, unprocessed attribute value 
		std::list<std::pair<std::string, common::AttributeValue> >& attrs,  	// output, processed attribute name-value pair
		std::list<std::string >& string_buffer,   		// buffer to store processed string attribute values
		std::list<std::vector<nostd::string_view> >& stringview_buffer,		// buffer used only for string array attributes 
		std::list<std::vector<double> >& dimensions_buffer)  	// buffer for array dimensions of nonscalar attribute values
{
    std::vector<double> attrvalue_dims_buffer; // dimensions of array attribute, cast to double

    matlab::data::ArrayType valtype = attrvalue.getType();
    matlab::data::ArrayDimensions attrdims = attrvalue.getDimensions();

    // TODO Consider using templates instead of a giant switchyard
    size_t nelements = matlab::data::getNumElements(attrdims);
    if (nelements == 1) { // scalar case
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
          //string_buffer.push_back(static_cast<std::string>(attrvalue_mda[0]));
          string_buffer.push_back(static_cast<std::string>(*(attrvalue_mda.begin())));
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, string_buffer.back()));
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
          matlab::data::StringArray attrvalue_mda = attrvalue;
	  std::vector<nostd::string_view> strarray_attr;
	  strarray_attr.reserve(nelements);
	  
	  for (auto itr = attrvalue_mda.begin(); itr < attrvalue_mda.end(); ++itr) {
             string_buffer.push_back(static_cast<std::string>(*itr));
	     strarray_attr.push_back(string_buffer.back());
	  }
	  stringview_buffer.push_back(strarray_attr);
          attrs.push_back(std::pair<std::string, common::AttributeValue>(attrname, 
	     nostd::span<const nostd::string_view>{&(*stringview_buffer.back().cbegin()), &(*stringview_buffer.back().cend())}));
       }
       // Add a size attribute to preserve the shape
       std::string& sizeattr{attrname + ".size"};
       matlab::data::ArrayDimensions::iterator copyfrom;
       for (copyfrom = attrdims.begin(); copyfrom != attrdims.end(); ++copyfrom) {
          attrvalue_dims_buffer.push_back(static_cast<double>(*copyfrom));
       }
       dimensions_buffer.push_back(attrvalue_dims_buffer);
       attrs.push_back(std::pair<std::string, common::AttributeValue>(sizeattr, 
	  nostd::span<const double>{&(*dimensions_buffer.back().cbegin()), 
	  &(*dimensions_buffer.back().cend())})); 
    }
}
} // namespace
