classdef Context
% Baggage-related actions on context instances

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function bg = extractBaggage(context)
        % Extract baggage from context
        %    B = OPENTELEMETRY.BAGGAGE.CONTEXT.EXTRACTBAGGAGE(CTXT)
        %    extracts baggage from context CTXT.
        % 
        %    See also OPENTELEMETRY.BAGGAGE.CONTEXT.INSERTBAGGAGE
            arguments
                context (1,1) opentelemetry.context.Context
            end
            bg = opentelemetry.baggage.Baggage(context);
        end

        function context = insertBaggage(context, baggage)
        % Insert baggage into context 
        %    NEWCTXT = OPENTELEMETRY.BAGGAGE.CONTEXT.INSERTBAGGAGE(CTXT, B)
        %    inserts baggage B into context CTXT, and returns a new
        %    context.
        %
        %    See also OPENTELEMETRY.BAGGAGE.CONTEXT.EXTRACTBAGGAGE
            arguments
                context (1,1) opentelemetry.context.Context
                baggage (1,1) opentelemetry.baggage.Baggage
            end
            context = baggage.insertBaggage(context);  % call Baggage class method
        end
    end
end
