classdef MeterProvider < opentelemetry.metrics.MeterProvider & handle
    % An SDK implementation of meter provider, which stores a set of configurations used
    % in a metrics system.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties(Access=private)
        isShutdown (1,1) logical = false
    end

    properties (SetAccess=private)
        MetricReader  % Metric reader controls how often metrics are exported
        View          % View object used to customize collected metrics
        Resource      % Attributes attached to all metrics
    end

    methods
        function obj = MeterProvider(varargin)
            % SDK implementation of meter provider
            %    MP = OPENTELEMETRY.SDK.METRICS.METERPROVIDER creates a meter
            %    provider that uses a periodic exporting metric reader and default configurations.
            %
            %    MP = OPENTELEMETRY.SDK.METRICS.METERPROVIDER(R) uses metric
            %    reader R. Currently, the only supported metric reader is the periodic
    	    %    exporting metric reader.
            %
            %    TP = OPENTELEMETRY.SDK.METRICS.METERPROVIDER(..., PARAM1, VALUE1,
            %    PARAM2, VALUE2, ...) specifies optional parameter name/value pairs.
            %    Parameters are:
            %       "View"        - View object used to customize collected metrics.
            %       "Resource"    - Additional resource attributes.
            %                       Specified as a dictionary.
            %
            %    See also OPENTELEMETRY.SDK.METRICS.PERIODICEXPORTINGMETRICREADER
            %    OPENTELEMETRY.SDK.METRICS.VIEW

            % explicit call to superclass constructor to make it a no-op
            obj@opentelemetry.metrics.MeterProvider("skip");

            if nargin == 1 && isa(varargin{1}, "libmexclass.proxy.Proxy")
                % This code branch is used to support conversion from API
                % MeterProvider to SDK equivalent, needed internally by
                % opentelemetry.sdk.metrics.Cleanup
                mpproxy = varargin{1};  
                assert(mpproxy.Name == "libmexclass.opentelemetry.MeterProviderProxy");
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.sdk.MeterProviderProxy", ...
                    "ConstructorArguments", {mpproxy.ID});
                % leave other properties unassigned, they won't be used
            else
                if nargin == 0 || ~isa(varargin{1}, "opentelemetry.sdk.metrics.PeriodicExportingMetricReader")
                    reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader();  % default metric reader
                else
                    reader = varargin{1};
                    varargin(1) = [];
                end
                obj.processOptions(reader, varargin{:});
            end
        end

        function addMetricReader(obj, reader)
            % ADDMETRICREADER Add an additional metric reader
            %    ADDMETRICREADER(MP, R) adds an additional metric reader
            %    R to the list of metric readers used by meter provider
            %    MP.
            %
            %    See also ADDVIEW, OPENTELEMETRY.SDK.METRICS.PERIODICEXPORTINGMETRICREADER
            arguments
         	    obj
                reader (1,1) {mustBeA(reader, "opentelemetry.sdk.metrics.PeriodicExportingMetricReader")}
            end
            obj.Proxy.addMetricReader(reader.Proxy.ID);
            obj.MetricReader = [obj.MetricReader, reader];
        end

        function addView(obj, view)
            % ADDVIEW Add an additional view
            %    ADDVIEW(MP, V) adds an additional view V. 
            %
            %    See also ADDMETRICREADER, OPENTELEMETRY.SDK.METRICS.VIEW
            arguments
         	    obj
                view (1,1) {mustBeA(view, "opentelemetry.sdk.metrics.View")}
            end
            obj.Proxy.addView(view.Proxy.ID);
            obj.View = [obj.View, view];
        end
            
        function success = shutdown(obj)
            % SHUTDOWN  Shutdown 
            %    SUCCESS = SHUTDOWN(MP) shuts down all metric readers associated with meter provider MP
    	    %    and return a logical that indicates whether shutdown was successful.
            %
            %    See also FORCEFLUSH
            if ~obj.isShutdown
                success = obj.Proxy.shutdown();
                obj.isShutdown = success;
            else
                success = true;
            end
        end

        function success = forceFlush(obj, timeout)
            % FORCEFLUSH Force flush
            %    SUCCESS = FORCEFLUSH(MP) immediately exports all metrics
            %    that have not yet been exported. Returns a logical that
            %    indicates whether force flush was successful.
            %
            %    SUCCESS = FORCEFLUSH(MP, TIMEOUT) specifies a TIMEOUT
            %    duration. Force flush must be completed within this time,
            %    or else it will fail.
            %
            %    See also SHUTDOWN
            if obj.isShutdown
                success = false;
            elseif nargin < 2 || ~isa(timeout, "duration")  % ignore timeout if not a duration
                success = obj.Proxy.forceFlush();
            else
                success = obj.Proxy.forceFlush(milliseconds(timeout)*1000); % convert to microseconds
            end
        end

    end

    methods(Access=private)
        function processOptions(obj, reader, optionnames, optionvalues)
            arguments
                obj
                reader
            end
            arguments (Repeating)
                optionnames (1,:) {mustBeTextScalar}
                optionvalues
            end

            validnames = ["Resource", "View"];
            resourcekeys = string.empty();
            resourcevalues = {};
            resource = dictionary(resourcekeys, resourcevalues);
            suppliedview = false;
            viewid = 0;
            for i = 1:length(optionnames)
                namei = validatestring(optionnames{i}, validnames);
                valuei = optionvalues{i};
                if strcmp(namei, "Resource")
                    if ~isa(valuei, "dictionary")
                        error("opentelemetry:sdk:metrics:MeterProvider:InvalidResourceType", ...
                            "Resource input must be a dictionary.");
                    end
                    resource = valuei;
                    resourcekeys = keys(valuei);
                    resourcevalues = values(valuei,"cell");
                    % collapse one level of cells, as this may be due to
                    % a behavior of dictionary.values
                    if all(cellfun(@iscell, resourcevalues))
                        resourcevalues = [resourcevalues{:}];
                    end
                elseif strcmp(namei, "View")
                    suppliedview = true;
                    view = valuei;
                    if ~isa(view, "opentelemetry.sdk.metrics.View")
                        error("opentelemetry:sdk:metrics:MeterProvider:InvalidViewType", ...
                            "View input must be a opentelemetry.sdk.metrics.View object.");
                    end
                    viewid = view.Proxy.ID;
                end
            end

            obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                "libmexclass.opentelemetry.sdk.MeterProviderProxy", ...
                "ConstructorArguments", {reader.Proxy.ID, resourcekeys, ...
                resourcevalues, suppliedview, viewid});
            obj.MetricReader = reader;
            obj.Resource = resource;
            if suppliedview
                obj.View = view;
            end
        end
    end
end
