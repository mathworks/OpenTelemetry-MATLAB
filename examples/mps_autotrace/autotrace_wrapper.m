function yf = autotrace_wrapper(varargin)
% Wrapper that automatically instruments and invokes a target function.
% The first input must be the function name (string or char). Any remaining
% inputs are passed as arguments to that function.
%
% Example:
%   yf = autotrace_wrapper("myfun", arg1, arg2, ...)

% Copyright 2026 The MathWorks, Inc.

% validate inputs
if nargin < 1
    error('autotrace_wrapper requires at least the function name as the first argument.');
end

func = varargin{1};
if ~(ischar(func) || isStringScalar(func))
    error('First argument must be a function name (char or string).');
end

% convert input func to handle
fh = str2func(func);

% remaining arguments to pass to the traced function
args = varargin(2:end);

% create tracer name 
tn = "autotrace_" + func;

% configure tracer provider
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
tp = opentelemetry.sdk.trace.TracerProvider(Resource=resource);
setTracerProvider(tp);

% create AutoTrace object
at = opentelemetry.autoinstrument.AutoTrace(fh, TracerName=tn);

% run the example
yf = beginTrace(at, args{:});