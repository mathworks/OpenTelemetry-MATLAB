classdef MeterProviderFixture < matlab.unittest.fixtures.Fixture
    % tests fixture for setting the global MeterProvider instance. 

    % Copyright 2025 The MathWorks, Inc.

    properties (SetAccess=immutable)
        MeterProvider (1,1)
    end

    methods
        function fixture = MeterProviderFixture(mp)
            fixture.MeterProvider = mp;
        end

        function setup(fixture)
            setMeterProvider(fixture.MeterProvider);
            fixture.addTeardown(@opentelemetry.metrics.Provider.unsetMeterProvider);
        end
    end

    methods (Access=protected)
        function tf = isCompatible(fixture1,fixture2)
            tf = fixture1.MeterProvider == fixture2.MeterProvider;
        end
    end
end