classdef ObservableResult
    % Object to record results from observable instrument callbacks

    % Copyright 2023-2024 The MathWorks, Inc
    properties (SetAccess=private, Hidden)
        Results = cell(1,0)    % observed results. Each observation in a cell
    end

    methods
        function obj = observe(obj, value, varargin)
            % OBSERVE   Record a new metric value
            %    R = OBSERVE(R, VAL) records a new metric in VAL. VAL must 
            %    be a real numeric scalar that can be converted to a
            %    double.
            %
            %    R = OBSERVE(R, VAL, ATTRIBUTES) also specifies attributes 
            %    as a dictionary.
            %
            %    R = OBSERVE(R, VAL, ATTRNAME1, ATTRVALUE1, ATTRNAME2,
            %    ATTRVALUE2, ...) specifies attributes as trailing
            %    name-value pairs.
            if isnumeric(value) && isscalar(value) && isreal(value)
                value = double(value);  
                if nargin == 2
                    attrs = {};
                elseif isa(varargin{1}, "dictionary")
                    attrkeys = keys(varargin{1}, "cell");
                    attrvals = values(varargin{1},"cell");
                    if all(cellfun(@iscell, attrkeys))
                        attrkeys = [attrkeys{:}];
                    end
                    if all(cellfun(@iscell, attrvals))
                        attrvals = [attrvals{:}];
                    end
                    attrs = reshape([attrkeys(:).'; attrvals(:).'], 1, []);
                else
                    if rem(length(varargin),2) == 0
                        attrs = varargin;
                    else  % mismatched attributes, ignore
                        attrs = {};
                    end
                end
                % check attribute names must be string or char
                for i = 1:2:length(attrs)
                    currkey = attrs{i};
                    if ~(isstring(currkey) || (ischar(currkey) && isrow(currkey)))
                        attrs = {};   % attribute name not char or string, ignore all attributes
                        break
                    end
                    attrs{i} = string(currkey); %#ok<AGROW>
                end
                obj.Results = [obj.Results {value} attrs];
            end
        end
    end

end
