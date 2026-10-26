function github_example()
% GITHUB_EXAMPLE  Demonstrates OpenTelemetry tracing in MATLAB with parent
%   context propagation from GitHub via TRACEPARENT environment variable.

% initialize tracing
runOnce(@initTracer);

%% Parse TRACEPARENT
traceparent = strtrim(string(getenv("TRACEPARENT")));
assert(strlength(traceparent) > 0, "TRACEPARENT environment variable is not set.");

% Format: <version>-<traceId>-<spanId>-<traceFlags>
parts = split(traceparent, "-");
assert(numel(parts) == 4, "TRACEPARENT is not in the expected format.");
traceIdHex    = parts(2);   % 32 hex chars
spanIdHex     = parts(3);   % 16 hex chars
traceFlagsHex = parts(4);   %  2 hex chars
issampled = bitand(hex2dec(traceFlagsHex), 1) == 1;

%% Build parent SpanContext
% IDs are passed as hex strings in W3C byte order; no endianness conversion needed
parentCtx = opentelemetry.trace.SpanContext(traceIdHex, spanIdHex, IsSampled=issampled);
parentscope = makeCurrent(parentCtx);

%% Create tracer
tracer = opentelemetry.trace.getTracer("matlab-otel-demo");

%% Level 1 — process-sensor-data (explicit parent from TRACEPARENT)
span1 = tracer.startSpan("process-sensor-data");
scope1 = makeCurrent(span1); %#ok<*NASGU>
span1.setAttributes("pipeline.name", "sensor-analysis", "pipeline.sample_rate_hz", int32(1000));

%% Level 2a — load-and-preprocess (implicit child of span1)
span2a = tracer.startSpan("load-and-preprocess");
scope2a = makeCurrent(span2a);
span2a.setAttributes("dataset.name", "vibration_sensor_03");

% Simulate loading sensor data
fs = 1000;            % sample rate (Hz)
t  = 0:1/fs:1-1/fs;  % 1 second of data
signal = sin(2*pi*50*t) + 0.5*sin(2*pi*120*t); % 50 Hz + 120 Hz
noisy  = signal + 0.8*randn(size(t));           % add noise
span2a.setAttributes("dataset.num_samples", int64(numel(noisy)));
span2a.addEvent("raw-data-loaded");

% Normalize
noisy = (noisy - mean(noisy)) / std(noisy);
span2a.addEvent("normalization-complete");
pause(0.15);

%% Level 3 — apply-fft-filter (implicit child of span2a)
span3 = tracer.startSpan("apply-fft-filter");
scope3 = makeCurrent(span3);
span3.setAttributes("filter.type", "lowpass-fft", "filter.cutoff_hz", int32(80));

% FFT filtering: keep only frequencies below 80 Hz
N   = numel(noisy);
Y   = fft(noisy);
f   = (0:N-1) * (fs/N);
Y(f > 80 & f < (fs - 80)) = 0;  % zero out high-frequency bins
filtered = real(ifft(Y));
span3.addEvent("fft-filter-applied");
span3.setAttributes("filter.output_samples", int64(numel(filtered)));
pause(0.1);

span3.endSpan();
clear("scope3");

span2a.endSpan();
clear("scope2a");

%% Level 2b — compute-statistics (implicit child of span1)
span2b = tracer.startSpan("compute-statistics");
scope2b = makeCurrent(span2b);
span2b.setAttributes("stats.signal", "filtered_vibration");

sig_mean = mean(filtered);
sig_std  = std(filtered);
sig_p2p  = max(filtered) - min(filtered);
span2b.setAttributes("stats.mean", sig_mean, "stats.std_dev", sig_std, "stats.peak_to_peak", sig_p2p);
span2b.addEvent("statistics-computed");
pause(0.1);

span2b.endSpan();
clear("scope2b");

%% End Level 1
span1.addEvent("pipeline-complete");
span1.endSpan();
clear("scope1");

fprintf("github_example complete. Trace ID: %s\n", traceIdHex);
end

function initTracer
% set up global TracerProvider
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
tp = opentelemetry.sdk.trace.TracerProvider(Resource=resource);
setTracerProvider(tp);

% set up global propagator
prop = opentelemetry.trace.propagation.TraceContextPropagator();
setTextMapPropagator(prop);
end

% This helper ensures the input function is only run once
function runOnce(fh)
persistent hasrun
if isempty(hasrun)
    feval(fh);
    hasrun = 1;
end
end
