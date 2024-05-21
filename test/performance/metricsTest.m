classdef metricsTest < matlab.perftest.TestCase
% performance tests for metrics

% Copyright 2024 The MathWorks, Inc.

    properties
        OtelConfigFile
        JsonFile
        PidFile
	    OtelcolName
        Otelcol
        ListPid
        ReadPidList
        ExtractPid
        Sigint
        Sigterm
    end
    
    methods (TestClassSetup)
        function setupOnce(testCase)
            % add directory where common setup and teardown code lives
            utilsfolder = fullfile(fileparts(mfilename('fullpath')), "..", "utils");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(utilsfolder));
           
            % add the callbacks folder to the path
            callbackfolder = fullfile(fileparts(mfilename('fullpath')), "..", "callbacks");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(callbackfolder));

            commonSetupOnce(testCase);

            % create a global meter provider
            mp = opentelemetry.sdk.metrics.MeterProvider();
            setMeterProvider(mp);
        end
    end

    methods (TestMethodSetup)
        function setup(testCase)
            commonSetup(testCase);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            % Flush any metrics that have not yet been exported
            mp = opentelemetry.metrics.Provider.getMeterProvider();
            opentelemetry.sdk.common.Cleanup.forceFlush(mp);

            commonTeardown(testCase);
        end
    end

    methods (Test)
        function testCreateCounter(testCase)
            % create a counter
            mt = opentelemetry.metrics.getMeter("foo");

            testCase.startMeasuring();
            c = createCounter(mt, "bar");
            testCase.stopMeasuring();
        end

        function testCreateUpDownCounter(testCase)
            % create an up-down-counter
            mt = opentelemetry.metrics.getMeter("foo");

            testCase.startMeasuring();
            c = createUpDownCounter(mt, "bar");
            testCase.stopMeasuring();
        end

        function testCreateHistogram(testCase)
            % create a histogram
            mt = opentelemetry.metrics.getMeter("foo");

            testCase.startMeasuring();
            h = createHistogram(mt, "bar");
            testCase.stopMeasuring();
        end

        function testCreateObservableCounter(testCase)
            % create an observable counter
            mt = opentelemetry.metrics.getMeter("foo");

            testCase.startMeasuring();
            c = createObservableCounter(mt, @callbackNoAttributes, "bar"); %#ok<*NASGU>
            testCase.stopMeasuring();
        end

        function testCreateObservableUpDownCounter(testCase)
            % create an observable up-down-counter
            mt = opentelemetry.metrics.getMeter("foo");

            testCase.startMeasuring();
            c = createObservableUpDownCounter(mt, @callbackNoAttributes, "bar"); %#ok<*NASGU>
            testCase.stopMeasuring();
        end

        function testCreateObservableGauge(testCase)
            % create an observable gauge
            mt = opentelemetry.metrics.getMeter("foo");

            testCase.startMeasuring();
            g = createObservableGauge(mt, @callbackNoAttributes, "bar");
            testCase.stopMeasuring();
        end

        function testCounterAdd(testCase)
            % increment a counter
            mt = opentelemetry.metrics.getMeter("foo");
            c = createCounter(mt, "bar");

            while(testCase.keepMeasuring)
                add(c, 5);
            end
        end

        function testUpDownCounterAdd(testCase)
            % Increment an up-down-counter
            mt = opentelemetry.metrics.getMeter("foo");
            c = createUpDownCounter(mt, "bar");

            while(testCase.keepMeasuring)
                add(c, -5);
            end
        end

        function testHistogramRecord(testCase)
            % record a histogram value
            mt = opentelemetry.metrics.getMeter("foo");
            h = createHistogram(mt, "bar");

            while(testCase.keepMeasuring)
                record(h, 111);
            end
        end

        function testCounterAttributes(testCase)
            % increment counter with attributes
            mt = opentelemetry.metrics.getMeter("foo");
            c = createCounter(mt, "bar");
            d = dictionary("Attribute2", "Value2");

            testCase.startMeasuring();
            add(c, 1, "Attribute1", "Value1")
            add(c, 2, d);
            add(c, 3, "Attribute3", "Value3");
            testCase.stopMeasuring();
        end

        function testGetMeter(testCase)
            % get a meter from the global meter provider instance
            testCase.startMeasuring();
            mt = opentelemetry.metrics.getMeter("foo"); 
            testCase.stopMeasuring();
        end

        function testCreateDefaultMeterProvider(testCase)
            % create default MeterProvider in the sdk
            testCase.startMeasuring();
            tp = opentelemetry.sdk.metrics.MeterProvider(); 
            testCase.stopMeasuring();
        end
    end
end