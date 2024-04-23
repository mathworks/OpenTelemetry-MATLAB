classdef Cleanup
% Clean up methods for TracerProvider, MeterProvider, and LoggerProvider

% Copyright 2023-2024 The MathWorks, Inc.

    methods (Static)
        function success = shutdown(p)
            % SHUTDOWN  Shutdown 
            %    SUCCESS = SHUTDOWN(P) shuts down all processors/readers 
            %    associated with P. P may be a tracer provider, a meter
            %    provider, or a logger provider. Returns a logical that 
            %    indicates whether shutdown was successful.
            %
            %    See also FORCEFLUSH

            success = true;
            % return false if input is not the right type
            issdk = isa(p, "opentelemetry.sdk.trace.TracerProvider") || ...
                    isa(p, "opentelemetry.sdk.metrics.MeterProvider") || ...
                    isa(p, "opentelemetry.sdk.logs.LoggerProvider");
            if issdk
                psdk = p;
            elseif isa(p, "opentelemetry.trace.TracerProvider")
                % convert to TracerProvider class in sdk
                try
                    psdk = opentelemetry.sdk.trace.TracerProvider(p.Proxy);
                catch
                    success = false;
                end
            elseif isa(p, "opentelemetry.metrics.MeterProvider")
                % convert to MeterProvider class in sdk
                try
                    psdk = opentelemetry.sdk.metrics.MeterProvider(p.Proxy);
                catch
                    success = false;
                end
            elseif isa(p, "opentelemetry.logs.LoggerProvider")
                % convert to LoggerProvider class in sdk
                try
                    psdk = opentelemetry.sdk.logs.LoggerProvider(p.Proxy);
                catch
                    success = false;
                end
            else
                success = false;
            end

            if success    % still not yet set to false, proceed to shutdown
                success = psdk.shutdown;
                if ~issdk
                    % API classes need extra work to swap to a no-op object
                    postShutdown(p);
                end
            end
        end

        function success = forceFlush(p, timeout)
            % FORCEFLUSH Force flush
            %    SUCCESS = FORCEFLUSH(P) immediately exports all spans,
            %    metrics, or log records that have not yet been exported. Returns a 
            %    logical that indicates whether force flush was successful.
            %
            %    SUCCESS = FORCEFLUSH(P, TIMEOUT) specifies a TIMEOUT
            %    duration. Force flush must be completed within this time,
            %    or else it will fail.
            %
            %    See also SHUTDOWN

            success = true;

            % return false if input is not the right type
            if isa(p, "opentelemetry.sdk.trace.TracerProvider") || ...
                    isa(p, "opentelemetry.sdk.metrics.MeterProvider") || ...
                    isa(p, "opentelemetry.sdk.logs.LoggerProvider")
                psdk = p;
            elseif isa(p, "opentelemetry.trace.TracerProvider")
                % convert to TracerProvider class in sdk
                try
                    psdk = opentelemetry.sdk.trace.TracerProvider(p.Proxy);
                catch
                    success = false;
                end
            elseif isa(p, "opentelemetry.metrics.MeterProvider")
                % convert to MeterProvider class in sdk
                try
                    psdk = opentelemetry.sdk.metrics.MeterProvider(p.Proxy);
                catch
                    success = false;
                end
            elseif isa(p, "opentelemetry.logs.LoggerProvider")
                % convert to LoggerProvider class in sdk
                try
                    psdk = opentelemetry.sdk.logs.LoggerProvider(p.Proxy);
                catch
                    success = false;
                end
            else
                success =  false;
            end

            if success    % still not yet set to false, proceed to force flush
                if nargin < 2 || ~isa(timeout, "duration")
                    success = psdk.forceFlush;
                else
                    success = psdk.forceFlush(timeout);
                end
            end
        end
    end

end
