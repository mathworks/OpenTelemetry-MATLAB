classdef ttrace < matlab.unittest.TestCase
    % tests for traces and spans

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
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            % add the utils folder to the path
            utilsfolder = fullfile(fileparts(mfilename('fullpath')), "utils");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(utilsfolder));
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
        function testBasic(testCase)
            % testBasic: names, default spankind and status, default resource, start and end times

            tracername = "foo";
            spanname = "bar";

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, tracername);
            sp = startSpan(tr, spanname);
            starttime = datetime("now", "TimeZone", "UTC");
            pause(1);
            endSpan(sp);
            endtime = datetime("now", "TimeZone", "UTC");

            % verify object properties
            verifyEqual(testCase, tr.Name, tracername);
            verifyEqual(testCase, tr.Version, "");
            verifyEqual(testCase, tr.Schema, "");
            verifyEqual(testCase, sp.Name, spanname);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check span and tracer names
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.scope.name), tracername);

            % check spankind and status
            verifyEqual(testCase, results.resourceSpans.scopeSpans.spans.kind, 1);   % internal
            verifyEmpty(testCase, fieldnames(results.resourceSpans.scopeSpans.spans.status));   % status unset

            % check start and end times
            % use a tolerance when testing times
            tol = seconds(2);
            verifyLessThanOrEqual(testCase, abs(datetime(double(string(...
                results.resourceSpans.scopeSpans.spans.startTimeUnixNano))/1e9, ...
                "convertFrom", "posixtime", "TimeZone", "UTC") - starttime), tol);
            verifyLessThanOrEqual(testCase, abs(datetime(double(string(...
                results.resourceSpans.scopeSpans.spans.endTimeUnixNano))/1e9, ...
                "convertFrom", "posixtime", "TimeZone", "UTC") - endtime), tol);

            % check resource
            resourcekeys = string({results.resourceSpans.resource.attributes.key});
            languageidx = find(resourcekeys == "telemetry.sdk.language");
            verifyNotEmpty(testCase, languageidx);
            verifyEqual(testCase, results.resourceSpans.resource.attributes(languageidx).value.stringValue, 'MATLAB');

            versionidx = find(resourcekeys == "telemetry.sdk.version");
            verifyNotEmpty(testCase, versionidx);
            versionpattern = digitsPattern + "." + digitsPattern + "." + digitsPattern;
            version_actual = results.resourceSpans.resource.attributes(versionidx).value.stringValue;
            verifyTrue(testCase, matches(version_actual, versionpattern), ...
                "Invalid version string: " + version_actual);

            nameidx = find(resourcekeys == "telemetry.sdk.name");
            verifyNotEmpty(testCase, nameidx);
            verifyEqual(testCase, results.resourceSpans.resource.attributes(nameidx).value.stringValue, 'opentelemetry');

            serviceidx = find(resourcekeys == "service.name");
            verifyNotEmpty(testCase, serviceidx);
            verifyEqual(testCase, results.resourceSpans.resource.attributes(serviceidx).value.stringValue, 'unknown_service');

            runtimeidx = find(resourcekeys == "process.runtime.name");
            verifyNotEmpty(testCase, runtimeidx);
            runtime_actual = results.resourceSpans.resource.attributes(runtimeidx).value.stringValue;
            verifyTrue(testCase, runtime_actual == "MATLAB" || runtime_actual == "MATLAB Runtime");

            runtimeversionidx = find(resourcekeys == "process.runtime.version");
            verifyNotEmpty(testCase, runtimeversionidx);
            runtimeversion_actual = results.resourceSpans.resource.attributes(runtimeversionidx).value.stringValue;
            verifyTrue(testCase, contains(runtimeversion_actual, "R" + digitsPattern + characterListPattern("ab")));
        end

        function testGetSetTracerProvider(testCase)
            % testGetSetTracerProvider: setting and getting global instance of TracerProvider
            customkey = "quux";
            customvalue = 1;
            tp = opentelemetry.sdk.trace.TracerProvider(opentelemetry.sdk.trace.SimpleSpanProcessor, ...
                "Resource", dictionary(customkey, customvalue));  % specify an arbitrary resource as an identifier
            setTracerProvider(tp);
            clear("tp");

            tracername = "foo";
            spanname = "bar";
            tr = opentelemetry.trace.getTracer(tracername);
            sp = startSpan(tr, spanname);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);

            % check a span has been created, and check its resource to identify the
            % correct TracerProvider has been used
            verifyNotEmpty(testCase, results);

            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), spanname);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.scope.name), tracername);

            resourcekeys = string({results{1}.resourceSpans.resource.attributes.key});
            idx = find(resourcekeys == customkey);
            verifyNotEmpty(testCase, idx);
            verifyEqual(testCase, results{1}.resourceSpans.resource.attributes(idx).value.doubleValue, customvalue);
        end

        function testImplicitParent(testCase)
            % testImplicitParent: parent and children relationship using implicit context

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            sp = startSpan(tr, "parent");
            scope = makeCurrent(sp); %#ok<NASGU>
            sp1 = startSpan(tr, "with parent"); %#ok<NASGU>
            clear("sp1");
            clear("scope")
            sp2 = startSpan(tr, "without parent"); %#ok<NASGU>
            clear("sp2");
            clear("sp");

            % perform test comparisons
            results = readJsonResults(testCase);

            % check span and tracer names
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.name, 'with parent');
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.scope.name, 'tracer');
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.name, 'without parent');
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.scope.name, 'tracer');
            verifyEqual(testCase, results{3}.resourceSpans.scopeSpans.spans.name, 'parent');
            verifyEqual(testCase, results{3}.resourceSpans.scopeSpans.scope.name, 'tracer');

            % check correct parent and children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{3}.resourceSpans.scopeSpans.spans.spanId);
            verifyEmpty(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId);
            verifyEmpty(testCase, results{3}.resourceSpans.scopeSpans.spans.parentSpanId);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.traceId, results{3}.resourceSpans.scopeSpans.spans.traceId);
            verifyNotEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.traceId, results{3}.resourceSpans.scopeSpans.spans.traceId);
        end

        function testExplicitParent(testCase)
            % testExplicitParent: parent and children relationship by passing context object explicitly

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            sp = startSpan(tr, "parent");
            context = opentelemetry.context.Context();  % empty context
            context = opentelemetry.trace.Context.insertSpan(context, sp);  % insert span into context
            sp1 = startSpan(tr, "child", Context=context);
            endSpan(sp1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);

            % check span and tracer names
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.name, 'child');
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.scope.name, 'tracer');
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.name, 'parent');
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.scope.name, 'tracer');

            % check correct parent and children relationship
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId, results{2}.resourceSpans.scopeSpans.spans.spanId);
            verifyEmpty(testCase, results{2}.resourceSpans.scopeSpans.spans.parentSpanId);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.traceId, results{2}.resourceSpans.scopeSpans.spans.traceId);
        end

        function testMakeCurrentNoOutput(testCase)
            % testMakeCurrentNoOutput: calling makeCurrent without an
            % output should return a warning
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            verifyWarning(testCase, @()makeCurrent(sp), "opentelemetry:trace:Span:makeCurrent:NoOutputSpecified");
            endSpan(sp);
        end

        function testSpanKind(testCase)
            % testSpanKind: specifying SpanKind

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            sp1 = startSpan(tr, "server", "SpanKind", "server");
            endSpan(sp1);
            sp2 = startSpan(tr, "consumer", "SpanKind", "consumer");
            endSpan(sp2);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.name, 'server');
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.kind, 2);   % server has a enum id of 2
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.name, 'consumer');
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.kind, 5);   % consumer has a enum id of 5
        end

        function testSpanName(testCase)
            % testSpanName: changing Span Name
            oldname = "helloworld";
            newname = "hello World!";

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            sp = startSpan(tr, oldname);
            verifyEqual(testCase, sp.Name, oldname);
            sp.Name = newname;
            verifyEqual(testCase, sp.Name, newname);
            endSpan(sp);
            % change to another name after span has ended, should be ignored
            sp.Name = "bogus";
            verifyEqual(testCase, sp.Name, newname);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.name), newname);
        end

        function testGetSpanContext(testCase)
            % testGetSpanContext: getSpanContext
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            ctxt = getSpanContext(sp);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyEqual(testCase, ctxt.TraceId, string(results{1}.resourceSpans.scopeSpans.spans.traceId));
            verifyEqual(testCase, ctxt.SpanId, string(results{1}.resourceSpans.scopeSpans.spans.spanId));
            verifyTrue(testCase, isa(ctxt.TraceState, "dictionary") && numEntries(ctxt.TraceState) == 0);  
            verifyEqual(testCase, ctxt.TraceFlags, "01");   % sampled flag should be on
        end

        function testSpanContext(testCase)
            % testSpanContext: create a new span context and specify it as
            % parent 
            traceid = "0123456789ABCDEF0123456789abcdef";
            spanid = "0000000000111122";
            issampled = false;
            isremote = false;
            tracestate = dictionary(["foo" "bar"], ["foo1" "bar1"]);
            tracestate_str = "bar=bar1,foo=foo1";
            sc = opentelemetry.trace.SpanContext(traceid, spanid, ...
                "IsSampled", issampled, "IsRemote", isremote, ...
                "TraceState", tracestate);

            % verify SpanContext object created correctly
            verifyEqual(testCase, sc.TraceId, lower(traceid));
            verifyEqual(testCase, sc.SpanId, spanid);
            verifyEqual(testCase, sc.TraceState, tracestate);
            verifyEqual(testCase, sc.TraceFlags, "00");   % sampled flag should be off
            verifyEqual(testCase, isRemote(sc), isremote); 

            % start a span and pass in context
            context = opentelemetry.trace.Context.insertSpan(...
                opentelemetry.context.Context, sc);
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar", "Context", context); 
            endSpan(sp);

            % start another span and declare parent implicitly
            curscope = makeCurrent(sc); %#ok<NASGU>
            sp1 = startSpan(tr, "quux");
            endSpan(sp1);
            clear("curscope");

            % perform test comparisons
            results = readJsonResults(testCase);

            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.traceId), ...
                lower(traceid));
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.parentSpanId), ...
                spanid);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.traceState), ...
                tracestate_str);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.traceId), ...
                lower(traceid));
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.parentSpanId), ...
                spanid);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.traceState), ...
                tracestate_str);
        end

        function testTime(testCase)
            % testTime: specifying start and end times
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            starttime = datetime(2000,1,1,10,0,0, "TimeZone", "UTC");
            endtime = datetime(2001, 8, 31, 7, 30, 0, "TimeZone", "UTC");
            sp = startSpan(tr, "foo", "StartTime", starttime);
            endSpan(sp, endtime);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyEqual(testCase, datetime(double(string(...
                results{1}.resourceSpans.scopeSpans.spans.startTimeUnixNano))/1e9, ...
                "convertFrom", "posixtime", "TimeZone", "UTC"), starttime);  % convert from nanoseconds to seconds
            % for end time, use a tolerance
            verifyLessThanOrEqual(testCase, abs(datetime(double(string(...
                results{1}.resourceSpans.scopeSpans.spans.endTimeUnixNano))/1e9, ...
                "convertFrom", "posixtime", "TimeZone", "UTC") - endtime), seconds(2));
        end

        function testStatus(testCase)
            % testStatus: setting status
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            setStatus(sp, "ok");
            endSpan(sp);

            sp1 = startSpan(tr, "quz");
            setStatus(sp1, "Error", "Something went wrong.")  % with description
            endSpan(sp1);

            % perform test comparisons
            results = readJsonResults(testCase);
            % status codes
            %   Unset: 0
            %   Ok:    1
            %   Error: 2
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.status.code, 1);
            verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.status.code, 2);
        end

        function testAttributes(testCase)
            % testAttributes: specifying attributes when starting spans

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            attributes = dictionary(["stringscalar", "charrow", "singlescalar", "doublescalar", ...
                "int8scalar", "uint16scalar", "int32scalar", "uint32scalar", "int64scalar", ...
                "uint64scalar", "logicalscalar", "singlearray", "doublearray", ...
                "int8array", "uint16array", "int32array", "uint32array", "int64array", ...
                "uint64array", "logicalarray", "stringarray", "cellstr", "datetime"], ...
                {"foo", 'bar', single(5), 10, ...
                uint8(2), int16(100), int32(10), uint32(20), int64(35), ...
                uint64(9999), false, single([1 2; 3 4]), [2 3; 4 5], int8(-2:2), ...
                uint16(1:10), int32(1:6), uint32((15:18).'), int64(reshape(1:4,2,1,2)), ...
                uint64([100 200; 300 400]), [true false true], ["foo", "bar", "quux", "quz"], ...
                {'foo', 'bar', 'quux', 'quz'}, datetime("now")});
            sp1 = startSpan(tr, "span", "Attributes", attributes);
            endSpan(sp1);

            % perform test comparisons
            results = readJsonResults(testCase);

            attrkeys = string({results{1}.resourceSpans.scopeSpans.spans.attributes.key});

            % scalars
            % string and char
            textscalars = ["stringscalar" "charrow"];
            for i = 1:length(textscalars)
                stringscidx = find(attrkeys == textscalars(i));
                verifyNotEmpty(testCase, stringscidx);
                verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.attributes(stringscidx).value.stringValue), ...
                    string(attributes{textscalars(i)}));
            end

            % floating point scalars
            floatscalars = ["single" "double"] + "scalar";
            for i = 1:length(floatscalars)
                floatscidx = find(attrkeys == floatscalars(i));
                verifyNotEmpty(testCase, floatscidx);
                verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(floatscidx).value.doubleValue, ...
                    double(attributes{floatscalars(i)}));
            end

            % integer scalars
            intscalars = ["int8" "uint16" "int32" "uint32" "int64" "uint64"] + "scalar";
            for i = 1:length(intscalars)
                intscidx = find(attrkeys == intscalars(i));
                verifyNotEmpty(testCase, intscidx);
                verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(intscidx).value.intValue, ...
                    char(string(attributes{intscalars(i)})));
            end

            % logical scalar
            logicalscidx = find(attrkeys == "logicalscalar");
            verifyNotEmpty(testCase, logicalscidx);
            verifyFalse(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(logicalscidx).value.boolValue);

            % arrays
            % floating point arrays
            floatarrays = ["single" "double"] + "array";
            for i = 1:length(floatarrays)
                floataridx = find(attrkeys == floatarrays(i));
                verifyNotEmpty(testCase, floataridx);
                verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(floataridx).value.arrayValue.values.doubleValue], ...
                    double(reshape(attributes{floatarrays(i)}, 1, [])));

                floatszidx = find(attrkeys == floatarrays(i) + ".size");
                verifyNotEmpty(testCase, floatszidx);
                verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(floatszidx).value.arrayValue.values.doubleValue], ...
                    size(attributes{floatarrays(i)}));
            end

            % integer arrays
            intarrays = ["int8" "uint16" "int32" "uint32" "int64" "uint64"] + "array";
            for i = 1:length(intarrays)
                intaridx = find(attrkeys == intarrays(i));
                verifyNotEmpty(testCase, intaridx);
                verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(intaridx).value.arrayValue.values.intValue})), ...
                    double(reshape(attributes{intarrays(i)},1,[])));

                intszidx = find(attrkeys == intarrays(i) + ".size");
                verifyNotEmpty(testCase, intszidx);
                verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(intszidx).value.arrayValue.values.doubleValue], ...
                    size(attributes{intarrays(i)}));
            end
            
            logicalaridx = find(attrkeys == "logicalarray");
            verifyNotEmpty(testCase, logicalaridx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(logicalaridx).value.arrayValue.values.boolValue], ...
                reshape(attributes{"logicalarray"},1,[]));

            logicalszidx = find(attrkeys == "logicalarray.size");
            verifyNotEmpty(testCase, logicalszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(logicalszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"logicalarray"}));

            % text arrays
            textarrays = ["stringarray" "cellstr"];
            for i = 1:length(textarrays)
                stringaridx = find(attrkeys == textarrays(i));
                verifyNotEmpty(testCase, stringaridx);
                verifyEqual(testCase, string({results{1}.resourceSpans.scopeSpans.spans.attributes(stringaridx).value.arrayValue.values.stringValue}), ...
                    string(attributes{textarrays(i)}));

                stringszidx = find(attrkeys == textarrays(i) + ".size");
                verifyNotEmpty(testCase, stringszidx);
                verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(stringszidx).value.arrayValue.values.doubleValue], ...
                    size(attributes{textarrays(i)}));
            end

            % datetime, not supported
            datetimeidx = find(attrkeys == "datetime");
            verifyEmpty(testCase, datetimeidx);
        end

        function testSetAttributes(testCase)
            % testSetAttributes: specifying attributes using SetAttributes method
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            % Name-value pairs
            nvattributes = {"stringscalar", "quux", "doublescalar", 15, "int32array", reshape(int32(1:6),2,3)};
            setAttributes(sp, nvattributes{:});
            % dictionary
            attributes = dictionary(["doublearray", "int64scalar", "stringarray"], ...
                {reshape(10:13,1,2,2), int64(155), ["I", "am", "a", "string", "array"]});
            setAttributes(sp, attributes);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);

            attrkeys = string({results{1}.resourceSpans.scopeSpans.spans.attributes.key});
            nvattributesstruct = struct(nvattributes{:});

            stringscidx = find(attrkeys == "stringscalar");
            verifyNotEmpty(testCase, stringscidx);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.attributes(stringscidx).value.stringValue), ...
                nvattributesstruct.stringscalar);

            doublescidx = find(attrkeys == "doublescalar");
            verifyNotEmpty(testCase, doublescidx);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(doublescidx).value.doubleValue, ...
                nvattributesstruct.doublescalar);

            i32aridx = find(attrkeys == "int32array");
            verifyNotEmpty(testCase, i32aridx);
            verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(i32aridx).value.arrayValue.values.intValue})), ...
                double(reshape(nvattributesstruct.int32array, 1, [])));

            i32szidx = find(attrkeys == "int32array.size");
            verifyNotEmpty(testCase, i32szidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(i32szidx).value.arrayValue.values.doubleValue], ...
                size(nvattributesstruct.int32array));

            doublearidx = find(attrkeys == "doublearray");
            verifyNotEmpty(testCase, doublearidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doublearidx).value.arrayValue.values.doubleValue], ...
                reshape(attributes{"doublearray"}, 1, []));

            doubleszidx = find(attrkeys == "doublearray.size");
            verifyNotEmpty(testCase, doubleszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doubleszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"doublearray"}));

            i64scidx = find(attrkeys == "int64scalar");
            verifyNotEmpty(testCase, i64scidx);
            verifyEqual(testCase, double(string(results{1}.resourceSpans.scopeSpans.spans.attributes(i64scidx).value.intValue)), ...
                double(attributes{"int64scalar"}));

            stringaridx = find(attrkeys == "stringarray");
            verifyNotEmpty(testCase, stringaridx);
            verifyEqual(testCase, string({results{1}.resourceSpans.scopeSpans.spans.attributes(stringaridx).value.arrayValue.values.stringValue}), ...
                reshape(attributes{"stringarray"}, 1, []));

            stringszidx = find(attrkeys == "stringarray.size");
            verifyNotEmpty(testCase, stringszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(stringszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"stringarray"}));
        end

        function testEvents(testCase)
            % testEvents: adding events
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            % Name-value pairs
            nvattributes = {"doublescalar", 5, "int32array", reshape(int32(1:6),2,3), ...
                "stringscalar", "baz"};
            addEvent(sp, "baz", nvattributes{:});
            event1time = datetime("now", "TimeZone", "UTC");
            % dictionary
            attributes = dictionary(["doublearray", "int64scalar", "stringarray"], ...
                {reshape(1:4,1,2,2), int64(350), ["one", "two", "three"; "four", "five","six"]});
            addEvent(sp, "quux", attributes);
            event2time = datetime("now", "TimeZone", "UTC");
            endSpan(sp);

            results = readJsonResults(testCase);
            nvattributesstruct = struct(nvattributes{:});

            tol = seconds(2);  % tolerance for testing times

            % event 1
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(1).name, 'baz');
            verifyLessThanOrEqual(testCase, abs(datetime(double(string(...
                results{1}.resourceSpans.scopeSpans.spans.events(1).timeUnixNano))/1e9, ...
                "convertFrom", "posixtime", "TimeZone", "UTC") - event1time), tol);

            event1keys = string({results{1}.resourceSpans.scopeSpans.spans.events(1).attributes.key});

            doublescidx = find(event1keys == "doublescalar");
            verifyNotEmpty(testCase, doublescidx);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(1).attributes(doublescidx).value.doubleValue, ...
                nvattributesstruct.doublescalar);

            i32aridx = find(event1keys == "int32array");
            verifyNotEmpty(testCase, i32aridx);
            verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.events(1).attributes(i32aridx).value.arrayValue.values.intValue})), ...
                reshape(double(nvattributesstruct.int32array), 1, []));

            i32szidx = find(event1keys == "int32array.size");
            verifyNotEmpty(testCase, i32szidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.events(1).attributes(i32szidx).value.arrayValue.values.doubleValue], ...
                size(nvattributesstruct.int32array));

            stringscidx = find(event1keys == "stringscalar");
            verifyNotEmpty(testCase, stringscidx);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.events(1).attributes(stringscidx).value.stringValue), ...
                nvattributesstruct.stringscalar);

            % event 2
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(2).name, 'quux');
            verifyLessThanOrEqual(testCase, abs(datetime(double(string(...
                results{1}.resourceSpans.scopeSpans.spans.events(2).timeUnixNano))/1e9, ...
                "convertFrom", "posixtime", "TimeZone", "UTC") - event2time), tol);

            event2keys = string({results{1}.resourceSpans.scopeSpans.spans.events(2).attributes.key});

            doublearidx = find(event2keys == "doublearray");
            verifyNotEmpty(testCase, doublearidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(doublearidx).value.arrayValue.values.doubleValue], ...
                reshape(attributes{"doublearray"}, 1, []));

            doubleszidx = find(event2keys == "doublearray.size");
            verifyNotEmpty(testCase, doubleszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(doubleszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"doublearray"}));

            i64scidx = find(event2keys == "int64scalar");
            verifyNotEmpty(testCase, i64scidx);
            verifyEqual(testCase, double(string(results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(i64scidx).value.intValue)), ...
                double(attributes{"int64scalar"}));

            stringaridx = find(event2keys == "stringarray");
            verifyNotEmpty(testCase, stringaridx);
            verifyEqual(testCase, string({results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(stringaridx).value.arrayValue.values.stringValue}), ...
                reshape(attributes{"stringarray"}, 1, []));

            stringszidx = find(event2keys == "stringarray.size");
            verifyNotEmpty(testCase, stringszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(stringszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"stringarray"}));

        end

        function testLinks(testCase)
            % testLinks: specifying links between spans

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp1 = startSpan(tr, "bar");
            ctxt1 = getSpanContext(sp1);
            % one link, no attributes
            l1 = opentelemetry.trace.Link(ctxt1);
            sp2 = startSpan(tr, "quux", "Links", l1);

            endSpan(sp2);

            % two links, with attributes in one link
            sp3 = startSpan(tr, "baz");
            ctxt3 = getSpanContext(sp3);
            l2attributes = {"StringScalar", "abcde", "DoubleArray", magic(3)};
            l2 = opentelemetry.trace.Link(ctxt1, l2attributes{:});
            l3 = opentelemetry.trace.Link(ctxt3);
            sp4 = startSpan(tr, "quz", "Links", [l2 l3]);

            endSpan(sp4);

            % end the rest of the spans
            endSpan(sp1);
            endSpan(sp3);

            results = readJsonResults(testCase);

            % one link, no attributes
            verifyLength(testCase, results{1}.resourceSpans.scopeSpans.spans.links, 1);  % only 1 link
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.links.traceId), ctxt1.TraceId);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.links.spanId), ctxt1.SpanId);

            % two links, with attributes
            % first link
            verifyLength(testCase, results{2}.resourceSpans.scopeSpans.spans.links, 2);  % 2 links
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links(1).traceId), ctxt1.TraceId);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links(1).spanId), ctxt1.SpanId);

            linkattrkeys = string({results{2}.resourceSpans.scopeSpans.spans.links(1).attributes.key});
            stringscidx = find(linkattrkeys == "StringScalar");
            verifyNotEmpty(testCase, stringscidx);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links(1).attributes(stringscidx).value.stringValue), ...
                l2attributes{2});
            doublearidx = find(linkattrkeys == "DoubleArray");
            verifyNotEmpty(testCase, doublearidx);
            verifyEqual(testCase, [results{2}.resourceSpans.scopeSpans.spans.links(1).attributes(doublearidx).value.arrayValue.values.doubleValue], ...
                reshape(l2attributes{4},1,[]));
            doubleszidx = find(linkattrkeys == "DoubleArray.size");
            verifyNotEmpty(testCase, doubleszidx);
            verifyEqual(testCase, [results{2}.resourceSpans.scopeSpans.spans.links(1).attributes(doubleszidx).value.arrayValue.values.doubleValue], ...
                size(l2attributes{4}));

            % second link
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links(2).traceId), ctxt3.TraceId);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links(2).spanId), ctxt3.SpanId);
        end

        function testInvalidSpanInputs(testCase)
            % testInvalidSpanInputs: Invalid inputs should be ignored and
            % not result in errors

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            % span name not a span; invalid context, spankind, attributes,
            % links; additional invalid option name
            spanname = [1 2; 3 4];
            sp = startSpan(tr, spanname, "Context", 1, "SpanKind", 2, ...
                "Attributes", 3, "Links", 4, "quux", 5);
            pause(1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check span name and other properties
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.name), ...
                string(spanname(1)));
            verifyEmpty(testCase, results.resourceSpans.scopeSpans.spans.parentSpanId);
            verifyEqual(testCase, results.resourceSpans.scopeSpans.spans.kind, 1);  % spankind internal
            verifyFalse(testCase, isfield(results.resourceSpans.scopeSpans.spans, "attributes"));
            verifyFalse(testCase, isfield(results.resourceSpans.scopeSpans.spans, "links"))
        end

        function testInvalidTracerInputs(testCase)
            % testInvalidTracerInputs: Invalid inputs should be ignored and
            % not result in errors

            tp = opentelemetry.sdk.trace.TracerProvider();
            % tracer name not a string; empty numeric version; duration
            % schema
            tracername = [1 2; 3 4];
            schema = seconds(1);
            tr = getTracer(tp, tracername, [], schema);
            sp = startSpan(tr, "foo");
            pause(1);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check tracer name, version, schema
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.scope.name), ...
                string(tracername(1)));
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.schemaUrl), ...
                string(schema));
        end

        function testInvalidAttributes(testCase)
            % testInvalidAttributes: Invalid attributes should be ignored and
            % not result in errors

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            % numeric attribute name not supported
            % duration attribute value not supported
            validattributename = "quux";
            validattributevalue = "quz";
            setAttributes(sp, 1, 2, validattributename, validattributevalue, "baz", hours(1));
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check attributes
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.attributes.key), ...
                validattributename);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.attributes.value.stringValue), ...
                validattributevalue);
        end

        function testInvalidEvent(testCase)
            % testInvalidEvent: Invalid event name and attributes should be ignored and
            % not result in errors

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            % numeric array event name
            % numeric attribute name not supported
            % duration attribute value not supported
            eventname = [1 2; 3 4];
            validattributename = "fred";
            validattributevalue = "thud";
            addEvent(sp, eventname, 10, 20, validattributename, validattributevalue, "baz", hours(1));
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check event name and attributes
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.events.name), ...
                string(eventname(1)));
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.events.attributes.key), ...
                validattributename);
            verifyEqual(testCase, string(results.resourceSpans.scopeSpans.spans.events.attributes.value.stringValue), ...
                validattributevalue);
        end

        function testInvalidStatus(testCase)
            % testInvalidStatus: Invalid status should be ignored
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            setStatus(sp, [10 20 30]);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            results = results{1};

            % check span status
            verifyEmpty(testCase, fieldnames(results.resourceSpans.scopeSpans.spans.status));   % status unset
        end

        function testInvalidSpanContext(testCase)
            % testInvalidSpanContext: create a span context with an invalid
            %                         trace or span ID
            traceid = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            spanid = "yyyyyyyyyyyyyyyy";
            sc = opentelemetry.trace.SpanContext(traceid, spanid);

            % verify SpanContext object uses default invalid IDs
            verifyEqual(testCase, sc.TraceId, string(repmat('0', 1, 32)));
            verifyEqual(testCase, sc.SpanId, string(repmat('0', 1, 16)));

            % start a span, pass in context, check it has no effect
            context = opentelemetry.trace.Context.insertSpan(...
                opentelemetry.context.Context, sc);
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar", "Context", context);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);

            verifyEmpty(testCase, results{1}.resourceSpans.scopeSpans.spans.parentSpanId);
        end
    end
end
