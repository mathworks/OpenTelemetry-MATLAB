classdef TracerProviderFixture < matlab.unittest.fixtures.Fixture
    % tests fixture for setting the global TracerProvider instance. 

    % Copyright 2025 The MathWorks, Inc.

    properties (SetAccess=immutable)
        TracerProvider (1,1)
    end

    methods
        function fixture = TracerProviderFixture(tp)
            fixture.TracerProvider = tp;
        end

        function setup(fixture)
            setTracerProvider(fixture.TracerProvider);
            fixture.addTeardown(@opentelemetry.trace.Provider.unsetTracerProvider);
        end
    end

    methods (Access=protected)
        function tf = isCompatible(fixture1,fixture2)
            tf = fixture1.TracerProvider == fixture2.TracerProvider;
        end
    end
end