classdef Link
% Specifies a link to a span

% Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Target 
    end

    properties (Access=?opentelemetry.trace.Tracer)
        Attributes (1,1) dictionary = dictionary(string.empty, {})
    end

    methods
        function obj = Link(targetspan, varargin)
            arguments
                targetspan (1,1) opentelemetry.trace.SpanContext
            end
            arguments (Repeating)
                varargin
            end            
            obj.Target = targetspan;
            if nargin > 1     % attributes
                attrs = validateAttributeInputs(varargin{:});
                obj.Attributes = attrs;                
            end
        end

        function obj = setAttributes(obj, varargin)
            attrs = validateAttributeInputs(varargin{:});
            % append new attributes to existing ones
            % use loop to support array of links
            for i = 1:numel(obj)
                obj(i).Attributes(keys(attrs)) = values(attrs);
            end
        end
    end

end

function attrs = validateAttributeInputs(varargin)
if nargin == 1
    attrs = varargin{1};
else
    if rem(nargin, 2) == 1
        error("Attributes must be a dictionary with string keys or name-value pairs.");
    end
    % wrap cells around attribute values to create string->cell dictionary
    varargin = reshape(varargin,2,[]);
    varargin(2,:) = cellfun(@(x){x}, varargin(2,:), "UniformOutput", false);
    attrs = dictionary(varargin{:});
end
if ~(isa(attrs, "dictionary") && isstring(keys(attrs)))
    error("Attributes must be a dictionary with string keys or name-value pairs.");
end
end