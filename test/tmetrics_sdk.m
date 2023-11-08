classdef tmetrics_sdk < matlab.unittest.TestCase
    % tests for metrics SDK

    % Copyright 2023 The MathWorks, Inc.

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
            commonSetupOnce(testCase);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            commonTeardown(testCase);
        end
    end

    methods (Test)
        function testCustomResource(testCase)
            % testCustomResource: check custom resources are included in
            % emitted metrics
            commonSetup(testCase)

            customkeys = ["foo" "bar"];
            customvalues = [1 5];
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                "Interval", seconds(2), "Timeout", seconds(1));
            mp = opentelemetry.sdk.metrics.MeterProvider(reader, ...
                "Resource", dictionary(customkeys, customvalues)); 
            
            m = getMeter(mp, "mymeter");
            c = createCounter(m, "mycounter");

            % create testing value 
            val = 10;

            % add value and attributes
            c.add(val);

            pause(2.5);

            clear mp;

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            resourcekeys = string({results.resourceMetrics.resource.attributes.key});
            for i = length(customkeys)
                idx = find(resourcekeys == customkeys(i));
                verifyNotEmpty(testCase, idx);
                verifyEqual(testCase, results.resourceMetrics.resource.attributes(idx).value.doubleValue, customvalues(i));
            end
        end

        function testShutdown(testCase)
            % testShutdown: shutdown method should stop exporting
            % of metrics
            commonSetup(testCase)

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                "Interval", seconds(2), "Timeout", seconds(1));
            mp = opentelemetry.sdk.metrics.MeterProvider(reader);

            % shutdown the meter provider
            verifyTrue(testCase, shutdown(mp));

            % create an instrument and add some values
            m = getMeter(mp, "foo");
            c = createCounter(m, "bar");
            c.add(5);

            % wait a little and then gather results, verify no metrics are
            % generated
            pause(2.5);
            clear mp;
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);
        end

        function testCleanupSdk(testCase)
            % testCleanupSdk: shutdown an SDK meter provider through the Cleanup class
            commonSetup(testCase)

            % Shut down an SDK meter provider instance
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                "Interval", seconds(2), "Timeout", seconds(1));
            mp = opentelemetry.sdk.metrics.MeterProvider(reader);

            % shutdown the meter provider through the Cleanup class
            verifyTrue(testCase, opentelemetry.sdk.common.Cleanup.shutdown(mp));

            % create an instrument and add some values
            m = getMeter(mp, "foo");
            c = createCounter(m, "bar");
            c.add(5);

            % wait a little and then gather results, verify no metrics are
            % generated
            pause(2.5);
            clear mp;
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);
        end

        function testCleanupApi(testCase)
            % testCleanupApi: shutdown an API meter provider through the Cleanup class
            commonSetup(testCase)

            % Shut down an API meter provider instance
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                "Interval", seconds(2), "Timeout", seconds(1));
            mp = opentelemetry.sdk.metrics.MeterProvider(reader);
            setMeterProvider(mp);
            clear("mp");
            mp_api = opentelemetry.metrics.Provider.getMeterProvider();

            % shutdown the API meter provider through the Cleanup class
            verifyTrue(testCase, opentelemetry.sdk.common.Cleanup.shutdown(mp_api));

            % create an instrument and add some values
            m = getMeter(mp_api, "foo");
            c = createCounter(m, "bar");
            c.add(5);

            % wait a little and then gather results, verify no metrics are
            % generated
            pause(2.5);
            clear("mp_api");
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);
        end
    end
end