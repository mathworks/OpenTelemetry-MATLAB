classdef Link
% Specifies a link to a span

% Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Target % Target span context 
    end

    properties (Access=?opentelemetry.trace.Tracer)
        Attributes (1,1) dictionary = dictionary(string.empty, {})  % Name-value pairs that describe the link
    end

    methods
        function obj = Link(targetspan, varargin)
            % Link object used to specify a relationship between two spans.
            %    LK = OPENTELEMETRY.TRACE.LINK(SPCTXT) returns a link
            %    object with the target span specified by its span context
            %    SPCTXT.
            %
            %    LK = OPENTELEMETRY.TRACE.LINK(SPCTXT, ATTRIBUTES) further
            %    describes the link using a name-value pairs specified as a
            %    dictionary.
            %
            %    LK = OPENTELEMETRY.TRACE.LINK(SPCTXT, ATTRNAME1,
            %    ATTRVALUE1, ATTRNAME2, ATTRVALUE2, ...) further describes
            %    the link using trailing name-value pairs.
            %
            %    See also OPENTELEMETRY.TRACE.TRACER.STARTSPAN
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
            % SETATTRIBUTES Append new attributes to existing ones
            %    NEWLK = SETATTRIBUTES(LK, ATTRIBUTES) appends extra
            %    attributes to the link, specified as a dictionary.
            %
            %    NEWLK = SETATTRIBUTES(LK, ATTRNAME1,
            %    ATTRVALUE1, ATTRNAME2, ATTRVALUE2, ...) appends extra 
            %    attributes to the link using trailing name-value pairs.
            attrs = validateAttributeInputs(varargin{:});
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
        % Mismatched name-value pairs. Ignore all attributes.
        attrs = dictionary(string.empty, {});
        return
    end
    % wrap cells around attribute values to create string->cell dictionary
    varargin = reshape(varargin,2,[]);
    varargin(2,:) = cellfun(@(x){x}, varargin(2,:), "UniformOutput", false);
    attrs = dictionary(varargin{:});
end
if ~(isa(attrs, "dictionary") && isstring(keys(attrs)))
    % Invalid attributes. Ignore.
    attrs = dictionary(string.empty, {});
end
end