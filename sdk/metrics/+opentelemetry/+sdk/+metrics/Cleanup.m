classdef Cleanup
% Clean up methods for MeterProvider in the API

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function success = shutdown(mp)
            % SHUTDOWN  Shutdown 
            %    SUCCESS = SHUTDOWN(MP) shuts down all span processors associated with 
            %    API meter provider MP and return a logical that indicates 
            %    whether shutdown was successful.
            %
            %    See also FORCEFLUSH

            % return false if input is not the right type
            if isa(mp, "opentelemetry.metrics.MeterProvider")
                % convert to MeterProvider class in sdk
                try
                    mpsdk = opentelemetry.sdk.metrics.MeterProvider(mp.Proxy);
                catch 
                    success = false;
                    return
                end
                success = mpsdk.shutdown;
                postShutdown(mp);
            else
                success = false;
            end
        end

        function success = forceFlush(mp, timeout)
            % FORCEFLUSH Force flush
            %    SUCCESS = FORCEFLUSH(MP) immediately exports all spans
            %    that have not yet been exported. Returns a logical that
            %    indicates whether force flush was successful.
            %
            %    SUCCESS = FORCEFLUSH(MP, TIMEOUT) specifies a TIMEOUT
            %    duration. Force flush must be completed within this time,
            %    or else it will fail.
            %
            %    See also SHUTDOWN

            % return false if input is not the right type
            if isa(mp, "opentelemetry.metrics.MeterProvider")
                % convert to MeterProvider class in sdk
                try
                    mpsdk = opentelemetry.sdk.metrics.MeterProvider(mp.Proxy);
                catch
                    success = false;
                    return
                end
                if nargin < 2 || ~isa(timeout, "duration")
                    success = mpsdk.forceFlush;
                else
                    success = mpsdk.forceFlush(timeout);
                end
            else
                success =  false;
            end
        end
    end

end
