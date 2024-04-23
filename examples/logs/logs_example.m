function yf = logs_example
% This example creates and emits logs from MATLAB code that fits a line 
% through a cluster of data points. It create a log record for each
% function call, and it also captures the parameters of the best fit line.

% Copyright 2024 The MathWorks, Inc.

% initialize logging during first run
runOnce(@initLogger);

% create a logger and start emitting logs
lg = opentelemetry.logs.getLogger("logs_example");
info(lg, "logs_example");

[x, y] = generate_data();
yf = best_fit_line(x,y);
end

function [x, y] = generate_data
% generate some random data
lg = opentelemetry.logs.getLogger("logs_example");
info(lg, "generate_data");

a = 1.5;
b = 0.8;
sigma = 5;
x = 1:100;
y = a * x + b + sigma * randn(1, 100);
end

function yf = best_fit_line(x, y)
% fit a line through points defined by inputs x and y
lg = opentelemetry.logs.getLogger("logs_example");
info(lg, "best_fit_line");

coefs = polyfit(x, y, 1);

% capture the coefficients
info(lg, coefs);

yf = polyval(coefs , x);
end

function initLogger
% set up global LoggerProvider
resource = dictionary("service.name", "OpenTelemetry-Matlab_examples");
lp = opentelemetry.sdk.logs.LoggerProvider(...
    opentelemetry.sdk.logs.SimpleLogRecordProcessor, Resource=resource);
setLoggerProvider(lp);
end

% This helper ensures the input function is only run once
function runOnce(fh)
persistent hasrun
if isempty(hasrun)
    feval(fh);
    hasrun = 1;
end
end
