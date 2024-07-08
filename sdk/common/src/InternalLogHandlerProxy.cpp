// Copyright 2024 The MathWorks, Inc.

#include "opentelemetry-matlab/sdk/common/InternalLogHandlerProxy.h"

#include "opentelemetry/sdk/common/global_log_handler.h"

#include "MatlabDataArray.hpp"

namespace internal_log = opentelemetry::sdk::common::internal_log;

namespace libmexclass::opentelemetry::sdk {
void InternalLogHandlerProxy::setLogLevel(libmexclass::proxy::method::Context& context) {
   matlab::data::StringArray loglevel_mda = context.inputs[0];
   matlab::data::MATLABString loglevelstr = loglevel_mda[0];

   internal_log::LogLevel loglevel;
   if (loglevelstr->compare(u"none")==0) {
      loglevel = internal_log::LogLevel::None;
   } else if (loglevelstr->compare(u"error")==0) {
      loglevel = internal_log::LogLevel::Error;
   } else if (loglevelstr->compare(u"warning")==0) {
      loglevel = internal_log::LogLevel::Warning;
   } else if (loglevelstr->compare(u"info")==0) {
      loglevel = internal_log::LogLevel::Info;
   } else {  
      assert(loglevelstr->compare(u"debug")==0);
      loglevel = internal_log::LogLevel::Debug;
   }
   internal_log::GlobalLogHandler::SetLogLevel(loglevel);
}

void InternalLogHandlerProxy::getLogLevel(libmexclass::proxy::method::Context& context) {
   internal_log::LogLevel loglevel = internal_log::GlobalLogHandler::GetLogLevel();
   std::string loglevelstr = internal_log::LevelToString(loglevel);
   loglevelstr[0] = tolower(loglevelstr[0]);   // LevelToString returns first letter capitalized

   matlab::data::ArrayFactory factory;
   auto loglevelstr_mda = factory.createScalar(loglevelstr);
   context.outputs[0] = loglevelstr_mda;
}
} // namespace libmexclass::opentelemetry
