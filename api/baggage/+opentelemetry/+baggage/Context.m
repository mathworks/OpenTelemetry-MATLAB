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

            if isa(context, "opentelemetry.context.Context")
                bg = opentelemetry.baggage.Baggage(context);
            else
                % return an empty baggage if input is invalid
                bg = opentelemetry.baggage.Baggage;
            end
        end

        function context = insertBaggage(context, baggage)
            % Insert baggage into context
            %    NEWCTXT = OPENTELEMETRY.BAGGAGE.CONTEXT.INSERTBAGGAGE(CTXT, B)
            %    inserts baggage B into context CTXT, and returns a new
            %    context.
            %
            %    See also OPENTELEMETRY.BAGGAGE.CONTEXT.EXTRACTBAGGAGE
            
            % do nothing if any input is invalid
            if isa(context, "opentelemetry.context.Context") && ...
                    isa(baggage, "opentelemetry.baggage.Baggage")
                context = baggage.insertBaggage(context);  % call Baggage class method
            end
        end
    end
end
