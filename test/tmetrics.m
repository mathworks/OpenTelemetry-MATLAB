classdef tmetrics < matlab.unittest.TestCase
    % tests for traces and spans

    % Copyright 2023 The MathWorks, Inc.

    properties
        OtelConfigFile
        OtelRoot
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
            verifyEqual(testCase, string(exporter.PreferredAggregationTemporality), "Cumulative");
        end


        function testExporterBasic(testCase)
            timeout = seconds(5);
            temporality = "Delta";
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter("Timeout", timeout, ...
                "PreferredAggregationTemporality", temporality);
            verifyEqual(testCase, exporter.Timeout, timeout);
            verifyEqual(testCase, string(exporter.PreferredAggregationTemporality), temporality);
        end

        
        function testDefaultReader(testCase)
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader();
            verifyEqual(testCase, string(class(reader.MetricExporter)), ...
                "opentelemetry.exporters.otlp.OtlpHttpMetricExporter");
            verifyEqual(testCase, reader.Interval, seconds(60));
            verifyEqual(testCase, reader.Timeout, seconds(30));
        end


        function testReaderBasic(testCase)
            exporter = opentelemetry.exporters.otlp.defaultMetricExporter;
            interval = seconds(1);
            timeout = seconds(0.5);
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                "Interval", interval, ...
                "Timeout", timeout);
            verifyEqual(testCase, reader.Interval, interval);
            verifyEqual(testCase, reader.Timeout, timeout);
        end

        
        function testAddMetricReader(testCase)
            metername = "foo";
            countername = "bar";
            exporter1 = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "Delta");
            exporter2 = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "Delta");
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
            pause(2.5);
            clear p;
            results = readJsonResults(testCase);
            result_count = numel(results);
            verifyEqual(testCase,result_count, 2);
        end


        function testCounterBasic(testCase)
            % test names and added value in Counter
            metername = "foo";
            countername = "bar";
            
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % verify MATLAB object properties
            verifyEqual(testCase, mt.Name, metername);
            verifyEqual(testCase, mt.Version, "");
            verifyEqual(testCase, mt.Schema, "");
            verifyEqual(testCase, ct.Name, countername);

            % create testing value 
            val = 10;

            % add value and attributes
            ct.add(val);

            % wait for collector response
            pause(2.5);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify meter and counter names
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);

            % fetch datapoint
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;

            % verify counter value
            verifyEqual(testCase, dp.asDouble, val);

        end

        function testCounterDelta(testCase)
            metername = "foo";
            countername = "bar";
            
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "Delta");
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % verify MATLAB object properties
            verifyEqual(testCase, mt.Name, metername);
            verifyEqual(testCase, mt.Version, "");
            verifyEqual(testCase, mt.Schema, "");
            verifyEqual(testCase, ct.Name, countername);

            % create testing value 
            vals = [10, 20];

            % add value and attributes
            ct.add(vals(1));
            pause(3);
            ct.add(vals(2));

            % fetch results
            pause(2.5);
            clear p;
            results = readJsonResults(testCase);
            dp1 = results{1}.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;
            dp2 = results{2}.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;

            % verify counter value
            verifyEqual(testCase, dp1.asDouble, vals(1));
            verifyEqual(testCase, dp2.asDouble, vals(2));
        end


        function testCounterAddAttributes(testCase)
            % test names, added value and attributes in Counter

            metername = "foo";
            countername = "bar";

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % create testing value and dictionary
            dict = dictionary("k1","v1","k2",5);
            vals = [1,2.4,3];
            dict_keys = keys(dict);
            dict_vals = values(dict);

            % add value and attributes
            ct.add(vals(1),dict);
            ct.add(vals(2),dict);
            ct.add(vals(3),dict_keys(1),dict_vals(1),dict_keys(2),dict_vals(2));

            % wait for collector response
            pause(2.5);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify meter and counter names
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);

            % fetch datapoint
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;

            % verify counter value
            verifyEqual(testCase, dp.asDouble, sum(vals));

            % verify counter attributes
            resourcekeys = string({dp.attributes.key});
            idx1 = find(resourcekeys == dict_keys(1));
            idx2 = find(resourcekeys == dict_keys(2));
            verifyEqual(testCase, string(dp.attributes(idx1).key), dict_keys(1));
            verifyEqual(testCase, string(dp.attributes(idx1).value.stringValue), dict_vals(1));
            verifyEqual(testCase, string(dp.attributes(idx2).key), dict_keys(2));
            verifyEqual(testCase, string(dp.attributes(idx2).value.stringValue), dict_vals(2));

        end


        function testCounterAddNegative(testCase)
            % test if counter value remain 0 when added negative value
            
            metername = "foo";
            countername = "bar";

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % add negative value to counter
            ct.add(-1);
            pause(2.5);

            % fetch results
            clear p;
            results = readJsonResults(testCase);
            results = results{end};
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;

            % verify that the counter value is still 0
            verifyEqual(testCase, dp.asDouble, 0);

        end


        function testUpDownCounterBasic(testCase)
            % test names and added value in UpDownCounter

            metername = "foo";
            countername = "bar";

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            ct = mt.createUpDownCounter(countername);

            % verify MATLAB object properties
            verifyEqual(testCase, mt.Name, metername);
            verifyEqual(testCase, mt.Version, "");
            verifyEqual(testCase, mt.Schema, "");
            verifyEqual(testCase, ct.Name, countername);

            % create testing value 
            val = -10;

            % add value and attributes
            ct.add(val);

            % wait for collector response time (2s)
            pause(5);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify meter and counter names
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);

            % fetch datapoint
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;

            % verify counter value
            verifyEqual(testCase, dp.asDouble, val);

        end


        function testUpDownCounterAddAttributes(testCase)
            % test names, added value and attributes in UpDownCounter

            metername = "foo";
            countername = "bar";

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            ct = mt.createUpDownCounter(countername);

            % create testing value and dictionary
            dict = dictionary("k1","v1","k2",5);
            vals = [2,-1.9,3];
            dict_keys = keys(dict);
            dict_vals = values(dict);

            % add value and attributes
            ct.add(vals(1),dict);
            ct.add(vals(2),dict);
            ct.add(vals(3),dict_keys(1),dict_vals(1),dict_keys(2),dict_vals(2));

            % wait for collector response
            pause(5);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;

            % verify counter value
            verifyEqual(testCase, dp.asDouble, sum(vals));

            % verify counter attributes
            resourcekeys = string({dp.attributes.key});
            idx1 = find(resourcekeys == dict_keys(1));
            idx2 = find(resourcekeys == dict_keys(2));
            verifyEqual(testCase, string(dp.attributes(idx1).key), dict_keys(1));
            verifyEqual(testCase, string(dp.attributes(idx1).value.stringValue), dict_vals(1));
            verifyEqual(testCase, string(dp.attributes(idx2).key), dict_keys(2));
            verifyEqual(testCase, string(dp.attributes(idx2).value.stringValue), dict_vals(2));

        end


        function testHistogramBasic(testCase)
            % test recorded values in histogram
            
            metername = "foo";
            histname = "bar";

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            hist = mt.createHistogram(histname);

            % verify MATLAB object properties
            verifyEqual(testCase, mt.Name, metername);
            verifyEqual(testCase, mt.Version, "");
            verifyEqual(testCase, mt.Schema, "");
            verifyEqual(testCase, hist.Name, histname);

            % create value for histogram
            val = 1;
    
            % record value
            hist.record(val);

            % wait for collector response
            pause(10);

            % fetch results
            clear p;
            results = readJsonResults(testCase);
            results = results{end};
            dp = results.resourceMetrics.scopeMetrics.metrics.histogram.dataPoints;
            bounds = dp.explicitBounds;
            counts = dp.bucketCounts;

            % verify meter and histogram names
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), histname);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);

            % verify statistics
            verifyEqual(testCase, dp.min, val);
            verifyEqual(testCase, dp.max, val);
            verifyEqual(testCase, dp.sum, val);
            
            % verify count in bucket
            len = length(counts);
            verifyEqual(testCase, str2double(counts{1}), sum(val<=bounds(1)));
            for i = 2:(len-1)
                lower = bounds(i-1);
                upper = bounds(i);
                expect_count = sum(val>lower & val<=upper);
                verifyEqual(testCase, str2double(counts{i}), expect_count);
            end
            verifyEqual(testCase, str2double(counts{len}), sum(val>bounds(len-1)));

        end


        function testHistogramRecordAttributes(testCase)
            % test recorded values and attributes in histogram
            metername = "foo";
            histname = "bar";

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter();
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            hist = mt.createHistogram(histname);

            % create value and attributes for histogram
            dict = dictionary("k1","v1","k2","v2");
            vals = [1,5,8.1];
            dict_keys = keys(dict);
            dict_vals = values(dict);
    
            % record value and attributes
            hist.record(vals(1),dict);
            hist.record(vals(2),dict);
            hist.record(vals(3),dict_keys(1),dict_vals(1),dict_keys(2),dict_vals(2));

            % wait for collector response
            pause(10);

            % fetch results
            clear p;
            results = readJsonResults(testCase);
            results = results{end};
            dp = results.resourceMetrics.scopeMetrics.metrics.histogram.dataPoints;
            bounds = dp.explicitBounds;
            counts = dp.bucketCounts;

            % verify statistics
            verifyEqual(testCase, dp.min, min(vals));
            verifyEqual(testCase, dp.max, max(vals));
            verifyEqual(testCase, dp.sum, sum(vals));
            
            % verify attributes
            resourcekeys = string({dp.attributes.key});
            idx1 = find(resourcekeys == dict_keys(1));
            idx2 = find(resourcekeys == dict_keys(2));
            verifyEqual(testCase, string(dp.attributes(idx1).key), dict_keys(1));
            verifyEqual(testCase, string(dp.attributes(idx1).value.stringValue), dict_vals(1));
            verifyEqual(testCase, string(dp.attributes(idx2).key), dict_keys(2));
            verifyEqual(testCase, string(dp.attributes(idx2).value.stringValue), dict_vals(2));
            
            % verify count in bucket
            len = length(counts);
            verifyEqual(testCase, str2double(counts{1}), sum(vals<=bounds(1)));
            for i = 2:(len-1)
                lower = bounds(i-1);
                upper = bounds(i);
                expect_count = sum(vals>lower & vals<=upper);
                verifyEqual(testCase, str2double(counts{i}), expect_count);
            end
            verifyEqual(testCase, str2double(counts{len}), sum(vals>bounds(len-1)));
        end


        function testHistogramDelta(testCase)
            metername = "foo";
            histname = "bar";

            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "Delta");
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                                        "Interval", seconds(2), "Timeout", seconds(1));
            p = opentelemetry.sdk.metrics.MeterProvider(reader);
            mt = p.getMeter(metername);
            hist = mt.createHistogram(histname);
    
            % record value and attributes
            rawvals = [1 6];
            vals = {[rawvals(1)], [rawvals(2)]};
            hist.record(rawvals(1));
            pause(2.5);
            hist.record(rawvals(2));

            % wait for collector response
            pause(2.5);

            % fetch results
            clear p;
            results = readJsonResults(testCase);
            rsize = size(results);
            for i = 1:rsize(2)
                dp = results{i}.resourceMetrics.scopeMetrics.metrics.histogram.dataPoints;
                bounds = dp.explicitBounds;
                counts = dp.bucketCounts;
                
                currentvals = vals{i};
                % verify statistics
                verifyEqual(testCase, dp.min, min(currentvals));
                verifyEqual(testCase, dp.max, max(currentvals));
                verifyEqual(testCase, dp.sum, sum(currentvals));
                
                % verify count in bucket
                len = length(counts);
                verifyEqual(testCase, str2double(counts{1}), sum(currentvals<=bounds(1)));
                for j = 2:(len-1)
                    lower = bounds(j-1);
                    upper = bounds(j);
                    expect_count = sum(currentvals>lower & currentvals<=upper);
                    verifyEqual(testCase, str2double(counts{j}), expect_count);
                end
                verifyEqual(testCase, str2double(counts{len}), sum(currentvals>bounds(len-1)));
            end
        end

        function testGetSetMeterProvider(testCase)
            % testGetSetMeterProvider: setting and getting global instance of MeterProvider
            exporter = opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "Delta");
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exporter, ...
                "Interval", seconds(2), "Timeout", seconds(1));
            mp = opentelemetry.sdk.metrics.MeterProvider(reader);
            setMeterProvider(mp);

            metername = "foo";
            countername = "bar";
            m = opentelemetry.metrics.getMeter(metername);
            c = createCounter(m, countername);
            
            % create testing value 
            val = 10;

            % add value and attributes
            c.add(val);

            pause(2.5);

            % perform test comparisons
            clear mp;
            results = readJsonResults(testCase);
            results = results{1};
            % check a counter has been created, and check its resource to identify the
            % correct MeterProvider has been used
            verifyNotEmpty(testCase, results);

            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);
        end
      
    end

end
