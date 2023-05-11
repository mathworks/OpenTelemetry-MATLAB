classdef TextMapCarrier
% Carrier that stores key-value pairs, used for injecting to and extracting 
% from HTTP headers

% Copyright 2023 The MathWorks, Inc.

    properties (Access=?opentelemetry.context.propagation.TextMapPropagator)
        Proxy
    end

    properties (Dependent, SetAccess=private)
        Headers
    end

    methods 
        function obj = TextMapCarrier(in)
            if nargin < 1
                in = strings(0,2);
            end
            
            if isa(in, "libmexclass.proxy.Proxy")
                obj.Proxy = in;
            elseif isstring(in) && ismatrix(in) && size(in,2) == 2  % Nx2 headers 
                obj.Proxy = libmexclass.proxy.Proxy("Name", ...
                    "libmexclass.opentelemetry.TextMapCarrierProxy", ...
                    "ConstructorArguments", {in});
            else
                error("Input must be an M-by-2 string array.")
            end
        end

        function headers = get.Headers(obj)
            headers = obj.Proxy.getHeaders();
        end
    end

end
