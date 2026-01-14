function me = generateException(errid, errmsg)
% Return a thrown exception 

% Copyright 2026 The MathWorks, Inc.

try
    exceptionHelper(errid, errmsg);
catch me    
end
end

function exceptionHelper(errid, errmsg)
me = MException(errid, errmsg);
throw(me);
end
