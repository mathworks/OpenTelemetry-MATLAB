classdef Cleanup
% Clean up methods for TracerProvider in the API

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function success = shutdown(tp)
            % SHUTDOWN  Shutdown 
            %    SUCCESS = SHUTDOWN(TP) shuts down all span processors associated with 
            %    API tracer provider TP and return a logical that indicates 
            %    whether shutdown was successful.
            %
            %    See also FORCEFLUSH

            % return false if input is not the right type
            if isa(tp, "opentelemetry.trace.TracerProvider")
                % convert to TracerProvider class in sdk
                try
                    tpsdk = opentelemetry.sdk.trace.TracerProvider(tp.Proxy);
                catch 
                    success = false;
                    return
                end
                success = tpsdk.shutdown;
                postShutdown(tp);
            else
                success = false;
            end
        end

        function success = forceFlush(tp, timeout)
            % FORCEFLUSH Force flush
            %    SUCCESS = FORCEFLUSH(TP) immediately exports all spans
            %    that have not yet been exported. Returns a logical that
            %    indicates whether force flush was successful.
            %
            %    SUCCESS = FORCEFLUSH(TP, TIMEOUT) specifies a TIMEOUT
            %    duration. Force flush must be completed within this time,
            %    or else it will fail.
            %
            %    See also SHUTDOWN

            % return false if input is not the right type
            if isa(tp, "opentelemetry.trace.TracerProvider")
                % convert to TracerProvider class in sdk
                try
                    tpsdk = opentelemetry.sdk.trace.TracerProvider(tp.Proxy);
                catch
                    success = false;
                    return
                end
                if nargin < 2 || ~isa(timeout, "duration")
                    success = tpsdk.forceFlush;
                else
                    success = tpsdk.forceFlush(timeout);
                end
            else
                success =  false;
            end
        end
    end

end
