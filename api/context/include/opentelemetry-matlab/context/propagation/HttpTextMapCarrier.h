// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "opentelemetry/context/propagation/text_map_propagator.h"
#include "opentelemetry/nostd/string_view.h"

#include <string>
#include <map>

namespace nostd = opentelemetry::nostd;
namespace context_propagation = opentelemetry::context::propagation;

namespace libmexclass::opentelemetry {
class HttpTextMapCarrier : public context_propagation::TextMapCarrier
{
public:
  HttpTextMapCarrier() : Headers(std::map<std::string, std::string>()) {}

  //copy constructor
  HttpTextMapCarrier(const HttpTextMapCarrier& in) : Headers(in.Headers) {}

  virtual nostd::string_view Get(nostd::string_view key) const noexcept override
  {
    std::string key_to_compare = key.data();
    auto it = Headers.find(key_to_compare);
    if (it != Headers.end())
    {
      return it->second;
    }
    return "";
  }

  virtual void Set(nostd::string_view key, nostd::string_view value) noexcept override
  {
    Headers.insert(std::pair<std::string, std::string>(std::string(key), std::string(value)));
  }

  std::map<std::string, std::string> Headers;
};
} // namespace libmexclass::opentelemetry
