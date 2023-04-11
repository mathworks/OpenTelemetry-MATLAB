// Copyright 2023 The MathWorks, Inc.

#include "mex.hpp"
#include "mexAdapter.hpp"

#include "libmexclass/mex/gateway.h"

#include "OtelMatlabProxyFactory.h"

class MexFunction : public matlab::mex::Function {
    public:
        void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
            libmexclass::mex::gateway<OtelMatlabProxyFactory>(inputs, outputs, getEngine());
        }
};
