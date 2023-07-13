classdef TextMapCarrier
% Carrier that stores name-value pairs, used for injecting into and extracting 
% from HTTP headers

% Copyright 2023 The MathWorks, Inc.

    properties (Access=?opentelemetry.context.propagation.TextMapPropagator)
        Proxy    % Proxy object to interface C++ code
    end

    properties (Dependent, SetAccess=private)
        Headers    % Name-value pairs either extracted from or to be injected into an HTTP header
    end

    methods 
        function obj = TextMapCarrier(in)
            % Name-value pair carrier, used for injecting into and extracting from HTTP headers.
            %    C = OPENTELEMETRY.CONTEXT.PROPAGATION.TEXTMAPCARRIER
            %    creates and empty carrier.
            %
            %    C = OPENTELEMETRY.CONTEXT.PROPAGATION.TEXTMAPCARRIER(HEADER)
            %    populates the carrier with name-value pairs stored in HTTP
            %    header. HEADER must be a Nx2 string array or cell array of
            %    character vectors.
            %
            %    See also
            %    OPENTELEMETRY.TRACE.PROPAGATION.TRACECONTEXTPROPAGATOR,
            %    OPENTELEMETRY.BAGGAGE.PROPAGATION.BAGGAGEPROPAGATOR
            if nargin < 1
                in = strings(0,2);
            end

            if isa(in, "libmexclass.proxy.Proxy")
                obj.Proxy = in;
            else
                if (isstring(in) || iscellstr(in)) && ismatrix(in) && size(in,2) == 2  % Nx2 headers
                    in = string(in);
                else
                    % if input is invalid, simply create an empty carrier
                    in = strings(0, 2);
                end
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.TextMapCarrierProxy", ...
                    "ConstructorArguments", {in});
            end
        end

        function headers = get.Headers(obj)
            headers = obj.Proxy.getHeaders();
        end
    end

end
