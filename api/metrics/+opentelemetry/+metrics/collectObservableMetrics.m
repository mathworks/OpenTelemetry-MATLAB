function result = collectObservableMetrics(fh)
% Internal function used to call callback functions for asynchronous
% instruments

% Copyright 2024 The MathWorks, Inc.

result = feval(fh);
