classdef AsynchronousInstrument < handle
    % Base class inherited by all asynchronous instruments

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Name        (1,1) string    % Instrument name
        Description (1,1) string    % Description of instrument
        Unit        (1,1) string    % Measurement unit
    end

    properties (SetAccess=private)
        Callbacks     % Callback function, called at each data export
    end

    properties (Constant, Hidden)
        DefaultTimeout = seconds(30)
    end

    properties (Access=private)
        Proxy   % Proxy object to interface C++ code
    end

    methods (Access=protected)
        function obj = AsynchronousInstrument(proxy, name, description, unit, callback)
            obj.Proxy = proxy;
            obj.Name = name;
            obj.Description = description;
            obj.Unit = unit;
            obj.Callbacks = callback;
        end

    end

    methods
        function addCallback(obj, callback, optionnames, optionvalues)
            % ADDCALLBACK   Add a callback function
            %    ADDCALLBACK(INST, CALLBACK) adds a callback function to
            %    collect metrics at every export. CALLBACK is specified as a
            %    function handle, and must accept no input and return one
            %    output of type opentelemetry.metrics.ObservableResult.
            %
            %    ADDCALLBACK(INST, CALLBACK, "Timeout", TIMEOUT) 
            %    also specifies the maximum time before callback is timed 
            %    out and its results not get recorded. TIMEOUT must be a
            %    positive duration scalar.
            %
            %    See also REMOVECALLBACK, OPENTELEMETRY.METRICS.OBSERVABLERESULT
            arguments
                obj
                callback
            end
            arguments (Repeating)
                optionnames 
                optionvalues
            end

            if isa(callback, "function_handle")
                % parse name-value pairs
                validnames = "Timeout";
                timeout = obj.DefaultTimeout; 
                for i = 1:length(optionnames)
                    try
                        validatestring(optionnames{i}, validnames);
                    catch
                        continue
                    end
                    timeout = optionvalues{i};
                end
                timeout = obj.mustBeScalarPositiveDurationTimeout(timeout);
                obj.Proxy.addCallback(callback, milliseconds(timeout));
                % append to Callbacks property
                if isempty(obj.Callbacks)
                    obj.Callbacks = callback;
                elseif isa(obj.Callbacks, "function_handle")
                    obj.Callbacks = {obj.Callbacks, callback};
                else
                    obj.Callbacks = [obj.Callbacks, {callback}];
                end
            end
        end

        function removeCallback(obj, callback)
            % REMOVECALLBACK   Remove a callback function
            %    REMOVECALLBACK(INST, CALLBACK) removes a callback function 
            %    CALLBACK specified as a function handle.
            %
            %    See also ADDCALLBACK
            if isa(callback, "function_handle") && ~isempty(obj.Callbacks)
                if iscell(obj.Callbacks)
                    found = cellfun(@(x)isequal(x,callback), obj.Callbacks);
                else   % scalar function handle
                    found = isequal(obj.Callbacks, callback);
                end
                if sum(found) > 0
                    idx = find(found,1);  % remove only the first match
                    obj.Proxy.removeCallback(idx);
                    % update Callback property
                    if isa(obj.Callbacks, "function_handle")
                        obj.Callbacks = [];
                    else
                        obj.Callbacks(idx) = [];  
                        if isscalar(obj.Callbacks)   % if there is only one left, remove the cell
                            obj.Callbacks = obj.Callbacks{1};
                        end
                    end
                end
            end
        end
    end

    methods (Static)
        function timeout = mustBeScalarPositiveDurationTimeout(timeout)
            if ~(isscalar(timeout) && isa(timeout, "duration") && timeout > 0)
                timeout = opentelemetry.metrics.AsynchronousInstrument.DefaultTimeout;   
            end
        end
    end
end
