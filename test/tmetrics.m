classdef tmetrics < matlab.unittest.TestCase
    % tests for metrics

    % Copyright 2023-2024 The MathWorks, Inc.

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
        ShortIntervalReader
        DeltaAggregationReader
        WaitTime
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            commonSetupOnce(testCase);
            
            % add the callbacks folder to the path
            callbackfolder = fullfile(fileparts(mfilename('fullpath')), "callbacks");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(callbackfolder));

            interval = seconds(2);
            timeout = seconds(1);
            testCase.ShortIntervalReader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(...
                opentelemetry.exporters.otlp.OtlpHttpMetricExporter(), ...
                "Interval", interval, "Timeout", timeout);
            testCase.DeltaAggregationReader = opentelemetry.sdk.metrics.PeriodicExportingMetricReader(...
                opentelemetry.exporters.otlp.OtlpHttpMetricExporter(...
                "PreferredAggregationTemporality", "Delta"), ...
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
        function testCounterBasic(testCase)
            % test names and added value in Counter
            metername = "foo";
            countername = "bar";
            
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % verify MATLAB object properties
            verifyEqual(testCase, mt.Name, metername);
            verifyEqual(testCase, mt.Version, "");
            verifyEqual(testCase, mt.Schema, "");
            verifyEqual(testCase, ct.Name, countername);

            % create testing value 
            val = 10;

            % add value
            ct.add(val);

            % wait for collector response
            pause(testCase.WaitTime);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify meter and counter names
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);

            % verify counter value
            verifyEqual(testCase, results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, val);

        end

        function testCounterDelta(testCase)
            metername = "foo";
            countername = "bar";
            
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.DeltaAggregationReader);
            mt = p.getMeter(metername);
            ct = mt.createCounter(countername);

            % verify MATLAB object properties
            verifyEqual(testCase, ct.Name, countername);

            % create testing value 
            vals = [10, 20];

            % add value
            ct.add(vals(1));
            pause(testCase.WaitTime);
            ct.add(vals(2));

            % fetch results
            pause(testCase.WaitTime);
            clear p;
            results = readJsonResults(testCase);

            % verify counter value
            verifyEqual(testCase, results{1}.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, vals(1));
            verifyEqual(testCase, results{2}.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, vals(2));
        end


        function testCounterAddAttributes(testCase)
            % test names, added value and attributes in Counter

            metername = "foo";
            countername = "bar";

            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
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
            pause(testCase.WaitTime);

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


        function testCounterInvalidAdd(testCase)
            % test if counter value remain 0 when added invalid values
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            ct = mt.createCounter("bar");

            % add negative value to counter
            ct.add(-1);
            % add add complex value
            ct.add(2+3i);
            % add nonscalar value
            ct.add(magic(3));
            % add nonnumerics
            ct.add("foobar");
            pause(testCase.WaitTime);

            % fetch results
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify that the counter value is still 0
            verifyEqual(testCase, ...
                results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, 0);
        end


        function testUpDownCounterBasic(testCase)
            % test names and added value in UpDownCounter

            metername = "foo";
            countername = "bar";

            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter(metername);
            ct = mt.createUpDownCounter(countername);

            % verify MATLAB object properties
            verifyEqual(testCase, ct.Name, countername);

            % create testing value 
            val = -10;

            % add value 
            ct.add(val);

            % wait for collector response time 
            pause(testCase.WaitTime);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify meter and counter names
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);

            % verify counter value
            verifyEqual(testCase, results.resourceMetrics.scopeMetrics.metrics.sum.dataPoints.asDouble, val);

        end


        function testUpDownCounterAddAttributes(testCase)
            % test names, added value and attributes in UpDownCounter
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            ct = mt.createUpDownCounter("bar");

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
            pause(testCase.WaitTime);

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

        function testUpDownCounterInvalidAdd(testCase)
            % add invalid values to UpDownCounter
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            ct = mt.createUpDownCounter("bar");

            % add add complex value
            ct.add(2+3i);
            % add nonscalar value
            ct.add(magic(3));
            % add nonnumerics
            ct.add("foobar");
            pause(testCase.WaitTime);

            % fetch results
            clear p;
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);    % results should be empty since all adds were invalid
        end


        function testHistogramBasic(testCase)
            % test recorded values in histogram
            
            metername = "foo";
            histname = "bar";

            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter(metername);
            hist = mt.createHistogram(histname);

            % verify MATLAB object properties
            verifyEqual(testCase, hist.Name, histname);

            % create value for histogram
            val = 1;
    
            % record value
            hist.record(val);

            % wait for collector response
            pause(testCase.WaitTime);

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
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            hist = mt.createHistogram("bar");

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
            pause(testCase.WaitTime);

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

        function testHistogramInvalidValue(testCase)
            % add invalid values to Histogram
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            h = mt.createHistogram("bar");

            % record add complex value
            h.record(2+3i);
            % record nonscalar value
            h.record(magic(3));
            % record nonnumerics
            h.record("foobar");
            pause(testCase.WaitTime);

            % fetch results
            clear p;
            results = readJsonResults(testCase);
            verifyEmpty(testCase, results);    % results should be empty since all adds were invalid
        end

        function testHistogramDelta(testCase)
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.DeltaAggregationReader);
            mt = p.getMeter("foo");
            hist = mt.createHistogram("bar");
    
            % record values
            rawvals = [1 6];
            vals = {[rawvals(1)], [rawvals(2)]};
            hist.record(rawvals(1));
            pause(testCase.WaitTime);
            hist.record(rawvals(2));

            % wait for collector response
            pause(testCase.WaitTime);

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
            mp = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            setMeterProvider(mp);

            metername = "foo";
            countername = "bar";
            m = opentelemetry.metrics.getMeter(metername);
            c = createCounter(m, countername);

            % create testing value 
            val = 10;

            % add value and attributes
            c.add(val);

            pause(testCase.WaitTime);

            %Shutdown the Meter Provider
            verifyTrue(testCase, mp.shutdown());

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};
            % check a counter has been created, and check its resource to identify the
            % correct MeterProvider has been used
            verifyNotEmpty(testCase, results);

            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.scope.name), metername);
        end
    end

    % parameters for asynchronous instruments
    properties (TestParameter)
        create_async = {@createObservableCounter, ...
            @createObservableUpDownCounter, @createObservableGauge};
        datapoint_name = {'sum', 'sum', 'gauge'};
    end

    methods (Test, ParameterCombination="sequential")
        function testAsynchronousInstrumentBasic(testCase, create_async, datapoint_name)
            % test basic functionalities of an observable counter

            testCase.assumeTrue(isequal(create_async, @createObservableGauge), ...
                "Sporadic failures for counters and updowncounters fixed in otel-cpp 1.14.0");

            countername = "bar";
            callback = @callbackNoAttributes;
            
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            %ct = mt.createObservableCounter(callback, countername);
            ct = create_async(mt, callback, countername);

            % verify MATLAB object properties
            verifyEqual(testCase, ct.Name, countername);

            % wait for collector response
            pause(testCase.WaitTime);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify counter name
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);

            % verify counter value
            verifyEqual(testCase, ...
                results.resourceMetrics.scopeMetrics.metrics.(datapoint_name).dataPoints.asDouble, 5);
        end

        function testAsynchronousInstrumentAttributes(testCase, create_async, datapoint_name)
            % test for attributes when observing metrics for an observable counter
            
            testCase.assumeTrue(isequal(create_async, @createObservableGauge), ...
                "Sporadic failures for counters and updowncounters fixed in otel-cpp 1.14.0");
            
            countername = "bar";
            callback = @callbackWithAttributes;
            
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            ct = create_async(mt, callback, countername); %#ok<NASGU>

            % wait for collector response
            pause(testCase.WaitTime);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify counter name
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);

            % verify counter values and attributes
            dp = results.resourceMetrics.scopeMetrics.metrics.(datapoint_name).dataPoints;
            attrvals = arrayfun(@(x)string(x.attributes.value.stringValue), dp);
            idxA = (attrvals == "A");
            idxB = (attrvals == "B");
            verifyEqual(testCase, dp(idxA).asDouble, 5);
            verifyEqual(testCase, string(dp(idxA).attributes.key), "Level");
            verifyEqual(testCase, string(dp(idxA).attributes.value.stringValue), "A");
            verifyEqual(testCase, dp(idxB).asDouble, 10);
            verifyEqual(testCase, string(dp(idxB).attributes.key), "Level");
            verifyEqual(testCase, string(dp(idxB).attributes.value.stringValue), "B");
        end

        function testAsynchronousInstrumentAnonymousCallback(testCase, create_async, datapoint_name)
            % use an anonymous function as callback

            testCase.assumeTrue(isequal(create_async, @createObservableGauge), ...
                "Sporadic failures for counters and updowncounters fixed in otel-cpp 1.14.0");

            countername = "bar";
            addvalue = 20;
            callback = @(x)callbackOneInput(addvalue);
            
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            ct = create_async(mt, callback, countername); %#ok<NASGU>

            % wait for collector response
            pause(testCase.WaitTime);

            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify counter name
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);

            % verify counter value
            verifyEqual(testCase, ...
                results.resourceMetrics.scopeMetrics.metrics.(datapoint_name).dataPoints.asDouble, 5 + addvalue);
        end

        function testAsynchronousInstrumentMultipleCallbacks(testCase, create_async, datapoint_name)
            % Observable counter with more than one callbacks
            countername = "bar";
            
            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            ct = create_async(mt, @callbackWithAttributes, countername);
            addCallback(ct, @callbackWithAttributes2)

            % wait for collector response
            pause(testCase.WaitTime);
            
            % fetch result
            clear p;
            results = readJsonResults(testCase);
            results = results{end};

            % verify counter name
            verifyEqual(testCase, string(results.resourceMetrics.scopeMetrics.metrics.name), countername);

            % verify counter values and attributes
            dp = results.resourceMetrics.scopeMetrics.metrics.(datapoint_name).dataPoints;
            attrvals = arrayfun(@(x)string(x.attributes.value.stringValue), dp);
            idxA = (attrvals == "A");
            idxB = (attrvals == "B");
            idxC = (attrvals == "C");
            verifyEqual(testCase, dp(idxA).asDouble, 5);
            verifyEqual(testCase, string(dp(idxA).attributes.key), "Level");
            verifyEqual(testCase, string(dp(idxA).attributes.value.stringValue), "A");
            verifyEqual(testCase, dp(idxB).asDouble, 10);
            verifyEqual(testCase, string(dp(idxB).attributes.key), "Level");
            verifyEqual(testCase, string(dp(idxB).attributes.value.stringValue), "B");
            verifyEqual(testCase, dp(idxC).asDouble, 20);
            verifyEqual(testCase, string(dp(idxC).attributes.key), "Level");
            verifyEqual(testCase, string(dp(idxC).attributes.value.stringValue), "C");
        end

        function testAsynchronousInstrumentRemoveCallback(testCase, create_async)
            % removeCallback method
            callback = @callbackNoAttributes;

            p = opentelemetry.sdk.metrics.MeterProvider(testCase.ShortIntervalReader);
            mt = p.getMeter("foo");
            ct = create_async(mt, callback, "foo2"); 
            removeCallback(ct, callback);

            % wait for collector response
            pause(testCase.WaitTime);

            % fetch result
            clear p;
            results = readJsonResults(testCase);

            verifyEmpty(testCase, results);   % expect empty result due to lack of callback
        end
      
    end

end
