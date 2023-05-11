function context = getCurrentContext()
% Get the current context object 

% Copyright 2023 The MathWorks, Inc.

proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.ContextProxy", ...
                    "ConstructorArguments", {"current"});
context = opentelemetry.context.Context(proxy);