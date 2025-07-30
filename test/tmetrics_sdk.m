classdef tmetrics_sdk < matlab.unittest.TestCase
    % tests for metrics SDK

    % Copyright 2023-2025 The MathWorks, Inc.

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
            % add the utils and fixtures folders to the path
            folders = fullfile(fileparts(mfilename('fullpath')), ["utils" "fixtures"]);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folders));
            commonSetupOnce(testCase);
            interval = seconds(2);
            timeout = seconds(1);
            testCase.ShortIntervalReader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(...
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
            % do not test the exporter class or the endpoint, as they
            % depend on which exporters are installed
            verifyEqual(testCase, exporter.Timeout, seconds(10));
            verifyEqual(testCase, string(exporter.PreferredAggregationTemporality), "cumulative");
        end


        function testExporterBasic(testCase)
            timeout = seconds(5);
            temporality = "delta";
            exporter = opentelemetry.exporters.otlp.defaultMetricExporter("Timeout", timeout, ...
                "PreferredAggregationTemporality", temporality);
            verifyEqual(testCase, exporter.Timeout, timeout);
            verifyEqual(testCase, string(exporter.PreferredAggregationTemporality), temporality);
        end

        function testOtlpFileExporter(testCase)
            % testOtlpFileExporter: use a file exporter to write to files

            testCase.assumeTrue(logical(exist("opentelemetry.exporters.otlp.OtlpFileMetricExporter", "class")), ...
                "Otlp file exporter must be installed.");

            % create temporary folder to write the output files
            folderfixture = testCase.applyFixture(...
                matlab.unittest.fixtures.TemporaryFolderFixture);
   
            % create file exporter
            output = fullfile(folderfixture.Folder,"output%n.json");
            alias = fullfile(folderfixture.Folder,"output_latest.json");
            exp = opentelemetry.exporters.otlp.OtlpFileMetricExporter(...
                FileName=output, AliasName=alias);
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(exp, ...
                Interval=testCase.ShortIntervalReader.Interval, ...
                Timeout=testCase.ShortIntervalReader.Timeout);
            p = opentelemetry.sdk.metrics.MeterProvider(reader);

            metername = "foo";
            countername = "bar";
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % create testing value 
            val = 10;

            % add value
            ct.add(val);

            % fetch result
            forceFlush(p);
            clear("ct", "mt", "p");
            resultstxt = readlines(alias);
            results = jsondecode(resultstxt(1));

            % verify meter and counter names
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);

            % verify counter value
            verifyEqual(testCase, results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, val);
        end
        
        function testDefaultReader(testCase)
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader();
            verifyEqual(testCase, class(reader.MetricExporter), ...
                class(opentelemetry.exporters.otlp.defaultMetricExporter));
            verifyEqual(testCase, reader.Interval, minutes(1));
            verifyEqual(testCase, reader.Interval.Format, 'm');  
            verifyEqual(testCase, reader.Timeout, seconds(30));
            verifyEqual(testCase, reader.Timeout.Format, 's');
        end


        function testReaderBasic(testCase)
            interval = hours(1);
            timeout = minutes(30);
            reader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader( ...
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
            exporter1 = opentelemetry.exporters.otlp.defaultMetricExporter(...
                "PreferredAggregationTemporality", "delta");
            exporter2 = opentelemetry.exporters.otlp.defaultMetricExporter(...
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
            
            clear mp;
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

        function testViewProperties(testCase)
            % testViewProperties: check view object changes the name and 
            % description of output metrics when schema, version, and units
            view_name = "counter_view";
            view_description = "view_description";
            view = opentelemetry.sdk.metrics.View(Name=view_name, ....
                Description=view_description, InstrumentType="Counter",MeterSchema="http://schema.org",MeterVersion="1.0.0",InstrumentUnit="ms");
            mp = opentelemetry.sdk.metrics.MeterProvider(...
                testCase.ShortIntervalReader, View=view); 

            m = getMeter(mp, "mymeter", "1.0.0", "http://schema.org");
            c = createCounter(m, "mycounter","Counter for meter with view properties","ms");

            m2 = getMeter(mp, "mymeter2", "2.0.0", "http://schema.org");
            c2 = createCounter(m2, "mycounter","Counter for meter with different version","ms");

            m3 = getMeter(mp, "mymeter3","1.0.0","http://notmyschema.org");
            c3 = createCounter(m3, "mycounter","Counter for meter with different schema","ms");

            m4 = getMeter(mp, "mymeter4", "1.0.0", "http://schema.org");
            c4 = createCounter(m4, "mycounter","Counter for meter with view properties different units","s");

            m4 = getMeter(mp, "mymeter5", "1.0.0", "http://schema.org");
            u = createUpDownCounter(m4, "updowncounter","UpDownCounter for meter with view properties","ms");

            

            % add value and attributes
            val = 10;
            c.add(val);
            c2.add(val);
            c3.add(val);
            c4.add(val);
            u.add(val);

            pause(testCase.WaitTime);

            clear mp;
            results = readJsonResults(testCase);
            results = results{end};

            % verify view name only on meter with matching properties
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics(1).metrics.name), view_name);
            verifyNotEqual(testCase, string(results.resourceMetrics.scopeMetrics(2).metrics.name), view_name);
            verifyNotEqual(testCase, string(results.resourceMetrics.scopeMetrics(3).metrics.name), view_name);
            verifyNotEqual(testCase, string(results.resourceMetrics.scopeMetrics(4).metrics.name), view_name);
            verifyNotEqual(testCase, string(results.resourceMetrics.scopeMetrics(5).metrics.name), view_name);
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
            
            clear mp;
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

        function testViewAggregation(testCase)
            % testViewAggregation: change aggregation of metric instruments
            metername = "foo";
            countername = "bar";
            view = opentelemetry.sdk.metrics.View(InstrumentType="Counter", ...
                InstrumentName=countername, Aggregation="LastValue");
            mp = opentelemetry.sdk.metrics.MeterProvider(...
                testCase.ShortIntervalReader, View=view); 

            m = getMeter(mp, metername);
            c = createCounter(m, countername);
            
            % add values
            maxi = 5;
            for i = 1:maxi
                c.add(i);
            end
            
            pause(testCase.WaitTime);
            
            clear mp;
            results = readJsonResults(testCase);
            results = results{end};

            % verify counter name
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);

            % verify counter value is the last value rather than the sum
            dp = results.resourceMetrics.scopeMetrics.metrics.gauge.dataPoints;
            verifyEqual(testCase, dp.asDouble, maxi);
        end

        function testViewAttributes(testCase)
            % testViewAttributes: filter out attributes
            metername = "foo";
            countername = "bar";
            view = opentelemetry.sdk.metrics.View;
            view.InstrumentType = "Counter";
            view.InstrumentName = countername; 
            view.AllowedAttributes= "Building";
            mp = opentelemetry.sdk.metrics.MeterProvider(...
                testCase.ShortIntervalReader, View=view); 

            m = getMeter(mp, metername);
            c = createCounter(m, countername);
            
            % add values
            values = 10:10:40;
            add(c, values(1), "Building", 1, "Room", 1);
            add(c, values(2), "Building", 1, "Room", 2);
            add(c, values(3), "Building", 1, "Room", 1);
            add(c, values(4), "Building", 1, "Room", 2);
            
            pause(testCase.WaitTime);
            
            clear mp;
            results = readJsonResults(testCase);
            results = results{end};

            % verify counter name
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);

            % verify "Room" attribute has been filtered out
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;
            verifyEqual(testCase, dp.asDouble, sum(values));
            verifyLength(testCase, dp.attributes, 1);
            verifyEqual(testCase, string(dp.attributes(1).key), "Building");
            verifyEqual(testCase, dp.attributes(1).value.doubleValue, 1);
        end

        function testViewAllowAllAttributes(testCase)
            % testViewAllowAllAttributes: Specify AllowedAttributes to
            % allow all
            metername = "foo";
            countername = "bar";
            buildingattr = "Building";
            roomattr = "Room";
            view = opentelemetry.sdk.metrics.View;
            view.InstrumentType = "Counter";
            view.InstrumentName = countername; 
            view.AllowedAttributes= "*";    % allow all attributes
            mp = opentelemetry.sdk.metrics.MeterProvider(...
                testCase.ShortIntervalReader, View=view); 

            m = getMeter(mp, metername);
            c = createCounter(m, countername);
            
            % add values
            values1 = [10 50];
            values2 = [20 60];
            add(c, values1(1), buildingattr, 1, roomattr, 1);
            add(c, values2(1), buildingattr, 1, roomattr, 2);
            add(c, values1(2), buildingattr, 1, roomattr, 1);
            add(c, values2(2), buildingattr, 1, roomattr, 2);
            
            pause(testCase.WaitTime);
            
            clear mp;
            results = readJsonResults(testCase);
            results = results{end};

            % verify counter name
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);

            % verify all attributes are included
            dp = results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints;
            verifyLength(testCase, dp, 2);
            verifyLength(testCase, dp(1).attributes, 2);
            attrkeys = string({dp(1).attributes.key});
            buildingidx = find(attrkeys == buildingattr);
            roomidx = find(attrkeys == roomattr);
            verifyNotEmpty(testCase, buildingidx);
            verifyNotEmpty(testCase, roomidx);

            % verify counts are correct
            roomidx = [dp(1).attributes(roomidx).value.doubleValue ...
                dp(2).attributes(roomidx).value.doubleValue];
            verifyEqual(testCase, dp(roomidx==1).asDouble, sum(values1));
            verifyEqual(testCase, dp(roomidx==2).asDouble, sum(values2));
        end

        function testMultipleViews(testCase)
            % testMultipleView: Applying multiple views to a meter provider

            % match instrument name
            instmatch_name = "match_instrument_name";
            instmatch = opentelemetry.sdk.metrics.View(Name=instmatch_name, ....
                InstrumentType="Counter", Instrumentname="foo(.*)");

            % match meter name
            metermatch_name = "match_meter_name";
            metermatch = opentelemetry.sdk.metrics.View;
            metermatch.Name = metermatch_name;
            metermatch.InstrumentType = "Counter"; 
            metermatch.MeterName = "abc";
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
            
            clear mp;
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

            % suppress internal warning logs about repeated shutdown
            nologs = SuppressInternalLogs; %#ok<NASGU>

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

            % suppress internal warning logs about repeated shutdown
            nologs = SuppressInternalLogs; %#ok<NASGU>

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

            % suppress internal warning logs about repeated shutdown
            nologs = SuppressInternalLogs; %#ok<NASGU>

            % Shut down an API meter provider instance
            mp = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            testCase.applyFixture(MeterProviderFixture(mp));  % set MeterProvider global instance
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
