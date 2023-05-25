classdef Context
% Baggage-related actions on context instances

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        % extract baggage from context
        function bg = extractBaggage(context)
            arguments
                context (1,1) opentelemetry.context.Context
            end
            bg = opentelemetry.baggage.Baggage(context);
        end

        % insert baggage into context and return new context
        function context = insertBaggage(context, baggage)
            arguments
                context (1,1) opentelemetry.context.Context
                baggage (1,1) opentelemetry.baggage.Baggage
            end
            context = baggage.insertBaggage(context);  % call Baggage class method
        end
    end
end
