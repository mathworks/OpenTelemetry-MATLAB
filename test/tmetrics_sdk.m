classdef tmetrics_sdk < matlab.unittest.TestCase
    % tests for metrics SDK

    % Copyright 2023-2024 The MathWorks, Inc.

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
        ShortIntervalReader
        WaitTime
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            commonSetupOnce(testCase);
            interval = seconds(2);
            timeout = seconds(1);
            testCase.ShortIntervalReader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(...
                opentelemetry.exporters.otlp.OtlpHttpMetricExporter(), ...
                "Interval", interval, "Timeout", timeout);
            testCase.WaitTime = seconds(interval * 1.25); 
        end
    end

    methods (TestMethodSetup)
        function setup(testCase)
            commonSetup(testCase);
        end
    end

    methods (TestMethodTeardown)
        function teardown(testCase)
            commonTeardown(testCase);
        end
    end

    methods (Test)
        function testDefaultExporter(testCase)
            exporter = opentelemetry.exporters.otlp.defaultMetricExporter;
            verifyEqual(testCase, string(class(exporter)), "opentelemetry.exporters.otlp.OtlpHttpMetricExporter");
            verifyEqual(testCase, string(exporter.Endpoint), "http://localhost:4318/v1/metrics");
            verifyEqual(testCase, exporter.Timeout, seconds(10));
            verifyEqual(testCase, string(exporter.PreferredAggregationTemporality), "cumulative");
        end


        function testExporterBasic(testCase)
            timeout = seconds(5);
            temporality = "delta";
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter("Timeout", timeout, ...
                "PreferredAggregationTemporality", temporality);
            verifyEqual(testCase, exporter.Timeout, timeout);
            verifyEqual(testCase, string(exporter.PreferredAggregationTemporality), temporality);
        end

        
        function testDefaultReader(testCase)
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader();
            verifyEqual(testCase, string(class(reader.MetricExporter)), ...
                "opentelemetry.exporters.otlp.OtlpHttpMetricExporter");
            verifyEqual(testCase, reader.Interval, minutes(1));
            verifyEqual(testCase, reader.Interval.Format, 'm');  
            verifyEqual(testCase, reader.Timeout, seconds(30));
            verifyEqual(testCase, reader.Timeout.Format, 's');
        end


        function testReaderBasic(testCase)
            exporter = opentelemetry.exporters.otlp.defaultMetricExporter;
            interval = hours(1);
            timeout = minutes(30);
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                "Interval", interval, ...
                "Timeout", timeout);
            verifyEqual(testCase, reader.Interval, interval);
            verifyEqual(testCase, reader.Interval.Format, 'h');  % should not be converted to other units  
            verifyEqual(testCase, reader.Timeout, timeout);
            verifyEqual(testCase, reader.Timeout.Format, 'm');
        end

        
        function testAddMetricReader(testCase)
            metername = "foo";
            countername = "bar";
            exporter1 = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "delta");
            exporter2 = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "delta");
            reader1 = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter1, ...,
                "Interval", seconds(2), "Timeout", seconds(1));
            reader2 = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter2, ...,
                "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader1);
            p.addMetricReader(reader2);
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % verify if the provider has two metric readers attached
            reader_count = numel(p.MetricReader);
            verifyEqual(testCase,reader_count, 2);

            % verify if the json results has two exported instances after
            % adding a single value
            ct.add(1);
            pause(testCase.WaitTime);
            clear p;
            results = readJsonResults(testCase);
            result_count = numel(results);
            verifyEqual(testCase,result_count, 2);
        end

        function testCustomResource(testCase)
            % testCustomResource: check custom resources are included in
            % emitted metrics
            customkeys = ["foo" "bar"];
            customvalues = [1 5];
            mp = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader, ...
                "Resource", dictionary(customkeys, customvalues)); 
            
            m = getMeter(mp, "mymeter");
            c = createCounter(m, "mycounter");

            % create testing value 
            val = 10;

            % add value and attributes
            c.add(val);

            pause(testCase.WaitTime);

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

        function testViewBasic(testCase)
            % testViewBasic: check view object changes the name and 
            % description of output metrics
            view_name = "counter_view";
            view_description = "view_description";
            view = opentelemetry.sdk.metrics.View(Name=view_name, ....
                Description=view_description, InstrumentType="Counter");
            mp = opentelemetry.sdk.metrics.MeterProvider(...
                testCase.ShortIntervalReader, View=view); 

            m = getMeter(mp, "mymeter", "1.0.0", "http://schema.org");
            c = createCounter(m, "mycounter");
            
            % add value and attributes
            val = 10;
            c.add(val);
            
            pause(testCase.WaitTime);
            
            clear m;
            results = readJsonResults(testCase);
            results = results{end};

            % verify view name and description
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), view_name);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.description), view_description);

            % fetch datapoint
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;

            % verify counter value
            verifyEqual(testCase, dp.asDouble, val);
        end
        

        function testViewHistogram(testCase)
            % testViewHistogram: Change histogram bins
            mp = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader); 
            
            view_name = "histogram_view";
            view_description = "view_description";
            meter_name = "mymeter";
            histogram_name = "myhistogram";
            bin_edges = [0; 100; 200; 300; 400; 500];
            view = opentelemetry.sdk.metrics.View(Name=view_name, ...
                Description=view_description, InstrumentName=histogram_name, ...
                InstrumentType="Histogram", MeterName=meter_name, ...
                HistogramBinEdges=bin_edges);
            
            addView(mp, view);
            
            m = mp.getMeter(meter_name);
            hist = m.createHistogram(histogram_name);
            
            % record values
            hist.record(0);
            hist.record(200);
            hist.record(201);
            hist.record(401);
            hist.record(402);
            
            % wait for collector response
            pause(testCase.WaitTime);
            
            clear m;
            results = readJsonResults(testCase);
            results = results{end};

            % verify view name and description
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), view_name);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.description), view_description);

            % fetch datapoint
            dp = results.resourceMetrics.scopeMetrics.metrics.histogram.dataPoints;

            % verify histogram sum
            expected_sum = 1204;
            verifyEqual(testCase, dp.sum, expected_sum);

            % verify histogram bounds
            verifyEqual(testCase, dp.explicitBounds, bin_edges);

            % verify histogram buckets
            expected_buckets = {'1'; '0'; '1'; '1'; '0'; '2'; '0'};
            verifyEqual(testCase, dp.bucketCounts, expected_buckets);
        end

        function testMultipleViews(testCase)
            % testMultipleView: Applying multiple views to a meter provider

            % match instrument name
            instmatch_name = "match_instrument_name";
            instmatch = opentelemetry.sdk.metrics.View(Name=instmatch_name, ....
                InstrumentType="Counter", Instrumentname="foo(.*)");

            % match meter name
            metermatch_name = "match_meter_name";
            metermatch = opentelemetry.sdk.metrics.View(Name=metermatch_name, ....
                InstrumentType="Counter", MeterName = "abc");
            mp = opentelemetry.sdk.metrics.MeterProvider(...
                testCase.ShortIntervalReader, View=instmatch); 
            addView(mp, metermatch);

            mxyz = getMeter(mp, "xyz");
            foo_name = "foo1";
            bar_name = "bar1";
            cfoo = createCounter(mxyz, foo_name);
            cbar = createCounter(mxyz, bar_name);
            mabc = getMeter(mp, "abc");
            quux_name = "quux1";
            cquux = createCounter(mabc, quux_name);
            
            valfoo = 10;
            valbar = 25;
            valquux = 40;
            cfoo.add(valfoo);
            cbar.add(valbar);
            cquux.add(valquux);
            
            pause(testCase.WaitTime);
            
            clear mxyz mabc;
            results = readJsonResults(testCase);
            results = vertcat(results{end}.resourceMetrics.scopeMetrics.metrics);

            % verify view name only applied to matched metric
            metricnames = {results.name};
            baridx = find(strcmp(metricnames, bar_name));
            fooidx = find(strcmp(metricnames, foo_name));
            quuxidx = find(strcmp(metricnames, quux_name));
            instmatchidx = find(strcmp(metricnames, instmatch_name));
            metermatchidx = find(strcmp(metricnames, metermatch_name));
            verifyNotEmpty(testCase, baridx);
            verifyEmpty(testCase, fooidx);
            verifyEmpty(testCase, quuxidx);
            verifyNotEmpty(testCase, instmatchidx);
            verifyNotEmpty(testCase, metermatchidx);

            % verify count value
            barcount = results(baridx).sum.dataPoints;
            verifyEqual(testCase, barcount.asDouble, valbar);
            instmatchcount = results(instmatchidx).sum.dataPoints;
            verifyEqual(testCase, instmatchcount.asDouble, valfoo);
            metermatchcount = results(metermatchidx).sum.dataPoints;
            verifyEqual(testCase, metermatchcount.asDouble, valquux);
        end

        function testShutdown(testCase)
            % testShutdown: shutdown method should stop exporting
            % of metrics
            mp = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);

            % shutdown the meter provider
            verifyTrue(testCase, shutdown(mp));

            % create an instrument and add some values
            m = getMeter(mp, "foo");
            c = createCounter(m, "bar");
            c.add(5);

            % wait a little and then gather results, verify no metrics are
            % generated
            pause(testCase.WaitTime);
            clear mp;
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);
        end

        function testCleanupSdk(testCase)
            % testCleanupSdk: shutdown an SDK meter provider through the Cleanup class

            % Shut down an SDK meter provider instance
            mp = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);

            % shutdown the meter provider through the Cleanup class
            verifyTrue(testCase, opentelemetry.sdk.common.Cleanup.shutdown(mp));

            % create an instrument and add some values
            m = getMeter(mp, "foo");
            c = createCounter(m, "bar");
            c.add(5);

            % wait a little and then gather results, verify no metrics are
            % generated
            pause(testCase.WaitTime);
            clear mp;
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);
        end

        function testCleanupApi(testCase)
            % testCleanupApi: shutdown an API meter provider through the Cleanup class
  
            % Shut down an API meter provider instance
            mp = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
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
            pause(testCase.WaitTime);
            clear("mp_api");
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);
        end
    end
end