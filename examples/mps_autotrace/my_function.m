function result = my_function(x,y,z,mode)
% Combine three numbers into one value according to mode.
% mode: 'equal' | 'linear' | 'custom'

% Copyright 2026 The MathWorks, Inc.

values = [x, y, z];

w = get_weights(mode, values);      
result = aggregate(values, w);     
end

function w = get_weights(mode, v)
switch lower(mode)
    case 'equal'
        w = ones(1,3) / 3;
    case 'linear'
        % weight proportional to value magnitude (nonnegative)
        vv = abs(v);
        if sum(vv) == 0
            w = ones(1,3) / 3;
        else
            w = vv / sum(vv);
        end
    case 'custom'
        % simple custom rule: emphasize middle element
        w = [0.2, 0.6, 0.2];
    otherwise
        error('Unknown mode. Use ''equal'', ''linear'', or ''custom''.');
end
end

function s = aggregate(v, w)
% weighted sum, then normalize to return scalar
s = sum(w .* v);
end