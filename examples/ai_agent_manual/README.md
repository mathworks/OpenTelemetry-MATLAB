# AI Agent Instrumentation Example
This example shows how to use both automatic and manual instrumentation to instrument an AI agent. The AI agent is taken from the ["Solve Simple Math Problem Using AI Agent"](https://github.com/matlab-deep-learning/llms-with-matlab/blob/main/examples/SolveSimpleMathProblemUsingAIAgent.md) example in the ["Large Language Models (LLMs) with MATLAB"](https://github.com/matlab-deep-learning/llms-with-matlab) package. It is tasked with finding the smallest root of a quadratic equation. To solve the problem, it sends requests to an OpenAI model and executes tool calls identified by the model.

This example uses automatic instrumentation to generate a span for each function call. It uses manual instrumentation to collect properties of OpenAI requests and responses such as input and output tokens and costs, as well as details about tool calls, and tag them as span attributes. The generated spans together form a trace.

In addition to tracing, metrics are also collected, including the total number of requests sent to OpenAI, and the total input and output tokens and costs.

The collected telemetry data reveals important details the AI agent, including
* The number of requests sent to OpenAI
* The details of each request and response
* Duration of each request
* Input and output tokens and costs for each request
* The number of calls to each tool
* Inputs and ouputs of each tool call
* Duration of each tool call 

## Running the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Start MATLAB. 
3. Ensure the OpenTelemetry-MATLAB add-on is installed and enabled.
4. Ensure the "Large Language Models (LLMs) with MATLAB" add-on is installed and enabled.
5. Run `run_example`.
