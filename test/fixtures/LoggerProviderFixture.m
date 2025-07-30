classdef LoggerProviderFixture < matlab.unittest.fixtures.Fixture
    % tests fixture for setting the global LoggerProvider instance. 

    % Copyright 2025 The MathWorks, Inc.

    properties (SetAccess=immutable)
        LoggerProvider (1,1)
    end

    methods
        function fixture = LoggerProviderFixture(lp)
            fixture.LoggerProvider = lp;
        end

        function setup(fixture)
            setLoggerProvider(fixture.LoggerProvider);
            fixture.addTeardown(@opentelemetry.logs.Provider.unsetLoggerProvider);
        end
    end

    methods (Access=protected)
        function tf = isCompatible(fixture1,fixture2)
            tf = fixture1.LoggerProvider == fixture2.LoggerProvider;
        end
    end
end