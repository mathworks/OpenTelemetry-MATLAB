classdef ttrace < matlab.unittest.TestCase
    % tests for traces and spans

    % Copyright 2023 The MathWorks, Inc.

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
            verifyEqual(testCase, results.resourceSpans.resource.attributes(versionidx).value.stringValue, '0.1.0');

            nameidx = find(resourcekeys == "telemetry.sdk.name");
            verifyNotEmpty(testCase, nameidx);
            verifyEqual(testCase, results.resourceSpans.resource.attributes(nameidx).value.stringValue, 'opentelemetry');

            serviceidx = find(resourcekeys == "service.name");
            verifyNotEmpty(testCase, serviceidx);
            verifyEqual(testCase, results.resourceSpans.resource.attributes(serviceidx).value.stringValue, 'unknown_service');
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

        function testSpanContext(testCase)
            % testSpanContext: getSpanContext
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            ctxt = getSpanContext(sp);
            endSpan(sp);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyEqual(testCase, ctxt.TraceId, string(results{1}.resourceSpans.scopeSpans.spans.traceId));
            verifyEqual(testCase, ctxt.SpanId, string(results{1}.resourceSpans.scopeSpans.spans.spanId));
            verifyEqual(testCase, ctxt.TraceState, "");
            verifyEqual(testCase, ctxt.TraceFlags, "01");   % sampled flag should be on
        end

        function testTime(testCase)
            % testTime: specifying start and end times
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            starttime = datetime(2000,1,1,10,0,0);
            endtime = datetime(2001, 8, 31, 7, 30, 0);
            sp = startSpan(tr, "foo", "StartTime", starttime);
            endSpan(sp, endtime);

            % perform test comparisons
            results = readJsonResults(testCase);
            verifyEqual(testCase, datetime(double(string(...
                results{1}.resourceSpans.scopeSpans.spans.startTimeUnixNano))/1e9, ...
                "convertFrom", "posixtime"), starttime);  % convert from nanoseconds to seconds
            % for end time, use a tolerance
            verifyLessThanOrEqual(testCase, abs(datetime(double(string(...
                results{1}.resourceSpans.scopeSpans.spans.endTimeUnixNano))/1e9, ...
                "convertFrom", "posixtime") - endtime), seconds(2));
        end

        function testAttributes(testCase)
            % testAttributes: specifying attributes when starting spans

            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "tracer");
            attributes = dictionary(["stringscalar", "doublescalar", "int32scalar", "uint32scalar", ...
                "int64scalar", "logicalscalar", "doublearray", "int32array", "uint32array", ...
                "int64array", "logicalarray", "stringarray"], {"foo", 10, int32(10), uint32(20), ...
                int64(35), false, [2 3; 4 5], int32(1:6), uint32((15:18).'), int64(reshape(1:4,2,1,2)), ...
                [true false true], ["foo", "bar", "quux", "quz"]});
            sp1 = startSpan(tr, "span", "Attributes", attributes);
            endSpan(sp1);

            % perform test comparisons
            results = readJsonResults(testCase);

            attrkeys = string({results{1}.resourceSpans.scopeSpans.spans.attributes.key});

            % scalars
            stringscidx = find(attrkeys == "stringscalar");
            verifyNotEmpty(testCase, stringscidx);
            verifyEqual(testCase, string(results{1}.resourceSpans.scopeSpans.spans.attributes(stringscidx).value.stringValue), attributes{"stringscalar"});

            doublescidx = find(attrkeys == "doublescalar");
            verifyNotEmpty(testCase, doublescidx);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(doublescidx).value.doubleValue, ...
                attributes{"doublescalar"});

            i32scidx = find(attrkeys == "int32scalar");
            verifyNotEmpty(testCase, i32scidx);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(i32scidx).value.intValue, ...
                char(string(attributes{"int32scalar"})));

            u32scidx = find(attrkeys == "uint32scalar");
            verifyNotEmpty(testCase, u32scidx);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(u32scidx).value.intValue, ...
                char(string(attributes{"uint32scalar"})));

            i64scidx = find(attrkeys == "int64scalar");
            verifyNotEmpty(testCase, i64scidx);
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(i64scidx).value.intValue, ...
                char(string(attributes{"int64scalar"})));

            logicalscidx = find(attrkeys == "logicalscalar");
            verifyNotEmpty(testCase, logicalscidx);
            verifyFalse(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(logicalscidx).value.boolValue);

            % arrays
            doublearidx = find(attrkeys == "doublearray");
            verifyNotEmpty(testCase, doublearidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doublearidx).value.arrayValue.values.doubleValue], ...
                reshape(attributes{"doublearray"}, 1, []));

            doubleszidx = find(attrkeys == "doublearray.size");
            verifyNotEmpty(testCase, doubleszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doubleszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"doublearray"}));

            i32aridx = find(attrkeys == "int32array");
            verifyNotEmpty(testCase, i32aridx);
            verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(i32aridx).value.arrayValue.values.intValue})), ...
                double(reshape(attributes{"int32array"},1,[])));

            i32szidx = find(attrkeys == "int32array.size");
            verifyNotEmpty(testCase, i32szidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(i32szidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"int32array"}));

            u32aridx = find(attrkeys == "uint32array");
            verifyNotEmpty(testCase, u32aridx);
            verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(u32aridx).value.arrayValue.values.intValue})), ...
                double(reshape(attributes{"uint32array"},1,[])));

            u32szidx = find(attrkeys == "uint32array.size");
            verifyNotEmpty(testCase, u32szidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(u32szidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"uint32array"}));

            i64aridx = find(attrkeys == "int64array");
            verifyNotEmpty(testCase, i64aridx);
            verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(i64aridx).value.arrayValue.values.intValue})), ...
                double(reshape(attributes{"int64array"},1,[])));

            i64szidx = find(attrkeys == "int64array.size");
            verifyNotEmpty(testCase, i64szidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(i64szidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"int64array"}));

            logicalaridx = find(attrkeys == "logicalarray");
            verifyNotEmpty(testCase, logicalaridx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(logicalaridx).value.arrayValue.values.boolValue], ...
                reshape(attributes{"logicalarray"},1,[]));

            logicalszidx = find(attrkeys == "logicalarray.size");
            verifyNotEmpty(testCase, logicalszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(logicalszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"logicalarray"}));

            stringaridx = find(attrkeys == "stringarray");
            verifyNotEmpty(testCase, stringaridx);
            verifyEqual(testCase, string({results{1}.resourceSpans.scopeSpans.spans.attributes(stringaridx).value.arrayValue.values.stringValue}), ...
                attributes{"stringarray"});

            stringszidx = find(attrkeys == "stringarray.size");
            verifyNotEmpty(testCase, stringszidx);
            verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(stringszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"stringarray"}));
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
            % dictionary
            attributes = dictionary(["doublearray", "int64scalar", "stringarray"], ...
                {reshape(1:4,1,2,2), int64(350), ["one", "two", "three"; "four", "five","six"]});
            addEvent(sp, "quux", attributes);
            endSpan(sp);

            results = readJsonResults(testCase);
            nvattributesstruct = struct(nvattributes{:});

            % event 1
            verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(1).name, 'baz');

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
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links{1}.traceId), ctxt1.TraceId);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links{1}.spanId), ctxt1.SpanId);

            linkattrkeys = string({results{2}.resourceSpans.scopeSpans.spans.links{1}.attributes.key});
            stringscidx = find(linkattrkeys == "StringScalar");
            verifyNotEmpty(testCase, stringscidx);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links{1}.attributes(stringscidx).value.stringValue), ...
                l2attributes{2});
            doublearidx = find(linkattrkeys == "DoubleArray");
            verifyNotEmpty(testCase, doublearidx);
            verifyEqual(testCase, [results{2}.resourceSpans.scopeSpans.spans.links{1}.attributes(doublearidx).value.arrayValue.values.doubleValue], ...
                reshape(l2attributes{4},1,[]));
            doubleszidx = find(linkattrkeys == "DoubleArray.size");
            verifyNotEmpty(testCase, doubleszidx);
            verifyEqual(testCase, [results{2}.resourceSpans.scopeSpans.spans.links{1}.attributes(doubleszidx).value.arrayValue.values.doubleValue], ...
                size(l2attributes{4}));

            % second link
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links{2}.traceId), ctxt3.TraceId);
            verifyEqual(testCase, string(results{2}.resourceSpans.scopeSpans.spans.links{2}.spanId), ctxt3.SpanId);
        end
    end
end
