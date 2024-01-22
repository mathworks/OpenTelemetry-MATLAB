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
        function addCallback(obj, callback)
            % ADDCALLBACK   Add a callback function
            %    ADDCALLBACK(INST, CALLBACK) adds a callback function to
            %    collect metrics at every export. CALLBACK is specified as a 
            %    function handle, and must accept no input and return one
            %    output of type opentelemetry.metrics.ObservableResult.
            %
            %    See also REMOVECALLBACK, OPENTELEMETRY.METRICS.OBSERVABLERESULT
            if isa(callback, "function_handle")
                callbackstr = string(func2str(callback));
                if ~startsWith(callbackstr, '@')   % do not allow anonymous functions for now
                    obj.Proxy.addCallback(callbackstr);
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
        end

        function removeCallback(obj, callback)
            % REMOVECALLBACK   Remove a callback function
            %    REMOVECALLBACK(INST, CALLBACK) removes a callback function 
            %    CALLBACK specified as a function handle.
            %
            %    See also ADDCALLBACK
            if isa(callback, "function_handle") && ~isempty(obj.Callbacks)
                callbackstr = string(func2str(callback));
                if iscell(obj.Callbacks)
                    found = strcmp(cellfun(@func2str, obj.Callbacks, 'UniformOutput', false), callbackstr);
                else   % scalar function handle
                    found = strcmp(func2str(obj.Callbacks), callbackstr);
                end
                if sum(found) > 0
                    obj.Proxy.removeCallback(callbackstr);
                    % update Callback property
                    if isa(obj.Callbacks, "function_handle")
                        obj.Callbacks = [];
                    else
                        obj.Callbacks(find(found,1)) = [];  % remove only the first match
                        if isscalar(obj.Callbacks)   % if there is only one left, remove the cell
                            obj.Callbacks = obj.Callbacks{1};
                        end
                    end
                end
            end
        end
    end
end
