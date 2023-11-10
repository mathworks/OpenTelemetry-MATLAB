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

        % function testViewCounter(testCase)
        %     % testCustomResource: check custom resources are included in
        %     % emitted metrics
        %     commonSetup(testCase)
        % 
        %     exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
        %     reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
        %         "Interval", seconds(2), "Timeout", seconds(1));
        %     mp = opentelemetry.sdk.metrics.MeterProvider(reader); 
        % 
        %     m = getMeter(mp, "mymeter");
        %     c = createCounter(m, "mycounter");
        % 
        %     % create testing value 
        %     val = 10;
        % 
        %     % add value and attributes
        %     c.add(val);
        % 
        %     pause(2.5);
        % 
        %     view = opentelemetry.sdk.metrics.View("View", "my View", "Unit", "Instrument", "kCounter", "mymeter", "", "", ["One" "Two" "Three"], "kDrop", [0 100 200 300 400 500]);
        % 
        %     addView(mp, view);
        % 
        %     clear mp;
        % 
        %     % % TODO: add test comparisons
        % end

        % function testViewHistogram(testCase)
        %     % testCustomResource: check custom resources are included in
        %     % emitted metrics
        %     commonSetup(testCase)
        % 
        %     exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
        %     reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
        %                                 "Interval", seconds(2), "Timeout", seconds(1));
        %     mp = opentelemetry.sdk.metrics.MeterProvider(reader);
        %     m = mp.getMeter("mymeter");
        %     hist = m.createHistogram("histogram");
        % 
        %     % create value for histogram
        %     val = 1;
        % 
        %     % record value
        %     hist.record(val);
        % 
        %     % wait for collector response
        %     pause(2.5);
        % 
        %     view = opentelemetry.sdk.metrics.View("View", "my View", "Unit", "Instrument", "kHistogram", "mymeter", "", "", ["One" "Two" "Three"], "kHistogram", [0 100 200 300 400 500]);
        % 
        %     addView(mp, view);
        % 
        %     clear mp;
        % 
        %     % % TODO: add test comparisons
        % end

    end
end