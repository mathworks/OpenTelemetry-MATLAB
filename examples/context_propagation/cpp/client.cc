// Copyright 2023 The MathWorks, Inc.

#include "opentelemetry/ext/http/client/http_client_factory.h"
#include "opentelemetry/ext/http/common/url_parser.h"
#include "opentelemetry/trace/semantic_conventions.h"
#include "HttpTextMapCarrier.h"

#include "opentelemetry/exporters/otlp/otlp_http_exporter_factory.h"
#include "opentelemetry/sdk/trace/simple_processor_factory.h"
#include "opentelemetry/sdk/trace/tracer_context.h"
#include "opentelemetry/sdk/trace/tracer_context_factory.h"
#include "opentelemetry/sdk/trace/tracer_provider_factory.h"
#include "opentelemetry/trace/provider.h"

#include "opentelemetry/context/propagation/global_propagator.h"
#include "opentelemetry/context/propagation/text_map_propagator.h"

#include <vector>
#include "opentelemetry/ext/http/client/http_client.h"
#include "opentelemetry/nostd/shared_ptr.h"

namespace
{

using namespace opentelemetry::trace;
namespace http_client = opentelemetry::ext::http::client;
namespace context     = opentelemetry::context;
namespace nostd       = opentelemetry::nostd;

void InitTracer()
{
  auto exporter = opentelemetry::exporter::otlp::OtlpHttpExporterFactory::Create();
  auto processor =
      opentelemetry::sdk::trace::SimpleSpanProcessorFactory::Create(std::move(exporter));
  std::vector<std::unique_ptr<opentelemetry::sdk::trace::SpanProcessor>> processors;
  processors.push_back(std::move(processor));
  std::unique_ptr<opentelemetry::sdk::trace::TracerContext> context =
      opentelemetry::sdk::trace::TracerContextFactory::Create(std::move(processors));
  std::shared_ptr<opentelemetry::trace::TracerProvider> provider =
      opentelemetry::sdk::trace::TracerProviderFactory::Create(std::move(context));
  // Set the global trace provider
  opentelemetry::trace::Provider::SetTracerProvider(provider);

  // set global propagator
  opentelemetry::context::propagation::GlobalTextMapPropagator::SetGlobalPropagator(
      opentelemetry::nostd::shared_ptr<opentelemetry::context::propagation::TextMapPropagator>(
          new opentelemetry::trace::propagation::HttpTraceContext()));
}

opentelemetry::nostd::shared_ptr<opentelemetry::trace::Tracer> get_tracer(std::string tracer_name)
{
  auto provider = opentelemetry::trace::Provider::GetTracerProvider();
  return provider->GetTracer(tracer_name);
}

void sendRequest(const std::string &url)
{
  auto http_client = http_client::HttpClientFactory::CreateSync();
  // define input to post to destination
  std::vector<uint8_t> body;
  uint8_t magic_square_size = 3;  // request 3x3 magic square
  body.push_back(magic_square_size);

  // start active span
  StartSpanOptions options;
  options.kind = SpanKind::kClient;  // client
  opentelemetry::ext::http::common::UrlParser url_parser(url);

  std::string span_name = url_parser.path_;
  auto span             = get_tracer("http-client")
                  ->StartSpan(span_name,
                              {{SemanticConventions::kHttpUrl, url_parser.url_},
                               {SemanticConventions::kHttpScheme, url_parser.scheme_},
                               {SemanticConventions::kHttpMethod, "POST"}},
                              options);
  auto scope = get_tracer("http-client")->WithActiveSpan(span);

  // inject current context into http header
  auto current_ctx = context::RuntimeContext::GetCurrent();
  HttpTextMapCarrier<http_client::Headers> carrier;
  auto prop = context::propagation::GlobalTextMapPropagator::GetGlobalPropagator();
  prop->Inject(carrier, current_ctx);

  // send http request
  http_client::Result result = http_client->Post(url, body, carrier.headers_);
  if (result)
  {
    // set span attributes
    auto status_code = result.GetResponse().GetStatusCode();
    span->SetAttribute(SemanticConventions::kHttpStatusCode, status_code);
    result.GetResponse().ForEachHeader(
        [&span](nostd::string_view header_name, nostd::string_view header_value) {
          span->SetAttribute("http.header." + std::string(header_name.data()), header_value);
          return true;
        });

    if (status_code >= 400)
    {
      span->SetStatus(StatusCode::kError);
    }
  }
  else
  {
    span->SetStatus(
        StatusCode::kError,
        "Response Status :" +
            std::to_string(
                static_cast<typename std::underlying_type<http_client::SessionState>::type>(
                    result.GetSessionState())));
  }
  // end span and export data
  span->End();
}

void CleanupTracer()
{
  std::shared_ptr<opentelemetry::trace::TracerProvider> none;
  opentelemetry::trace::Provider::SetTracerProvider(none);
}

}  // namespace

int main(int argc, char *argv[])
{
  InitTracer();
  constexpr char default_host[]   = "localhost";
  constexpr char default_path[]   = "/magic";
  constexpr uint16_t default_port = 9910;
  uint16_t port;

  // The port the validation service listens to can be specified via the command line.
  if (argc > 1)
  {
    port = (uint16_t)(atoi(argv[1]));
  }
  else
  {
    port = default_port;
  }

  std::string url = "http://" + std::string(default_host) + ":" + std::to_string(port) +
                    std::string(default_path);
  sendRequest(url);
  CleanupTracer();
}
