function logger = getLogger(trname, varargin)
% Create a logger from the global logger provider instance 
%    LG = OPENTELEMETRY.LOGS.GETLOGGER(NAME) returns a logger with the
%    specified name created from the global logger provider instance.
%
%    LG = OPENTELEMETRY.LOGS.GETLOGGER(NAME, VERSION, SCHEMA) also
%    specifies the logger version and the URL that documents the schema
%    of the generated log records.
%
%    See also OPENTELEMETRY.SDK.LOGS.LOGGERPROVIDER,
%    OPENTELEMETRY.LOGS.LOGGER,
%    OPENTELEMETRY.LOGS.PROVIDER.SETLOGGERPROVIDER

% Copyright 2024 The MathWorks, Inc.

provider = opentelemetry.logs.Provider.getLoggerProvider();
logger = getLogger(provider, trname, varargin{:});
