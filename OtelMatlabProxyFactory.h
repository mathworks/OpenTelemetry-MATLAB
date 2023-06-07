// Copyright 2023 The MathWorks, Inc.

#pragma once

#include "libmexclass/proxy/Factory.h"

class OtelMatlabProxyFactory : public libmexclass::proxy::Factory {
  public:
    OtelMatlabProxyFactory() {}
    virtual libmexclass::proxy::MakeResult
    make_proxy(const libmexclass::proxy::ClassName& class_name,
               const libmexclass::proxy::FunctionArguments& constructor_arguments);
};
