
#include "MatlabDataArray.hpp"
#include "mex.hpp"
#include "cppmex/detail/mexErrorDispatch.hpp"
#include "cppmex/detail/mexEngineUtilImpl.hpp"
#include "cppmex/detail/mexExceptionImpl.hpp"
#include "cppmex/detail/mexExceptionType.hpp"
#include "cppmex/detail/mexIOAdapterImpl.hpp"
#include "cppmex/detail/mexApiAdapterImpl.hpp"
#include "cppmex/detail/mexFutureImpl.hpp"
#include "cppmex/detail/mexTaskReferenceImpl.hpp"


#include "opentelemetry/metrics/observer_result.h"
#include "opentelemetry/nostd/shared_ptr.h"
#include "opentelemetry/nostd/variant.h"

#include "opentelemetry-matlab/metrics/MeasurementFetcher.h"
#include "opentelemetry-matlab/common/attribute.h"

namespace metrics_api = opentelemetry::metrics;
namespace nostd = opentelemetry::nostd;

namespace libmexclass::opentelemetry {
void MeasurementFetcher::Fetcher(metrics_api::ObserverResult observer_result, void * fcn_name_ptr)
{
  if (nostd::holds_alternative<
          nostd::shared_ptr<metrics_api::ObserverResultT<double>>>(observer_result))
  {
    auto future = mlptr->fevalAsync(static_cast<std::string*>(fcn_name_ptr)->c_str(), std::vector<matlab::data::Array>());
    try {
        matlab::data::ObjectArray resultobj = future.get();
	auto futureresult = mlptr->getPropertyAsync(resultobj, 0, u"Results");
	matlab::data::CellArray resultdata = futureresult.get();
	size_t n = resultdata.getNumberOfElements();
	size_t i = 0;
	while (i < n) {
	    matlab::data::TypedArray<double> val_mda = resultdata[i];
	    double val = val_mda[0];

	    ProcessedAttributes attrs;
	    size_t j = 1;
	    while (i+j < n && resultdata[i+j].getType() == matlab::data::ArrayType::MATLAB_STRING) {
                matlab::data::StringArray attrname_mda = resultdata[i+j];
                std::string attrname = static_cast<std::string>(attrname_mda[0]);
		matlab::data::Array attrvalue = resultdata[i+j+1];

		processAttribute(attrname, attrvalue, attrs);
		j += 2;
	    }
            nostd::get<nostd::shared_ptr<metrics_api::ObserverResultT<double>>>(
                observer_result)->Observe(val, attrs.Attributes);
	    i += j;
	}

    } catch(...) {
	// ran into an error in the callback, just do nothing and return
    }
  }
}

std::shared_ptr<matlab::engine::MATLABEngine> MeasurementFetcher::mlptr = nullptr;
}  // namespace
