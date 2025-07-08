classdef tlogs < matlab.unittest.TestCase
    % tests for logs

    % Copyright 2024-2025 The MathWorks, Inc.

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
        ForceFlushTimeout
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            % add the utils folder to the path
            utilsfolder = fullfile(fileparts(mfilename('fullpath')), "utils");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(utilsfolder));
            commonSetupOnce(testCase);
            testCase.ForceFlushTimeout = seconds(2);
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
            % testBasic: emitLogRecord with minimal inputs
            loggername = "foo";
            logseverity = "debug";
            logmessage = "bar";

            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, loggername);
            emitLogRecord(lg, logseverity, logmessage);
            expectedtimestamp = datetime("now", "TimeZone", "UTC");

            % verify object properties
            verifyEqual(testCase, lg.Name, loggername);
            verifyEqual(testCase, lg.Version, "");
            verifyEqual(testCase, lg.Schema, "");

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, 1);
            if ~isempty(results)
                results = results{1};

                % check logger name, log body and severity, trace and span IDs 
                verifyEqual(testCase, string(results.resourceLogs.scopeLogs.scope.name), loggername);
                verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.severityText), upper(logseverity));
                verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.body.stringValue), logmessage);
                verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.traceId), "");
                verifyEqual(testCase, string(results.resourceLogs.scopeLogs.logRecords.spanId), "");

                % check timestamp
                % use a tolerance when testing times
                tol = seconds(4);
                verifyLessThanOrEqual(testCase, abs(datetime(double(string(...
                    results.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano))/1e9, ...
                    "convertFrom", "posixtime", "TimeZone", "UTC") - expectedtimestamp), tol); 
                % by default, Timestamp and ObservedTimestamp should be identical
                verifyEqual(testCase, results.resourceLogs.scopeLogs.logRecords.observedTimeUnixNano, ...
                    results.resourceLogs.scopeLogs.logRecords.timeUnixNano);

                % check resource
                resourcekeys = string({results.resourceLogs.resource.attributes.key});
                languageidx = find(resourcekeys == "telemetry.sdk.language");
                verifyNotEmpty(testCase, languageidx);
                verifyEqual(testCase, results.resourceLogs.resource.attributes(languageidx).value.stringValue, 'MATLAB');

                versionidx = find(resourcekeys == "telemetry.sdk.version");
                verifyNotEmpty(testCase, versionidx);
                versionpattern = digitsPattern + "." + digitsPattern + "." + digitsPattern;
                version_actual = results.resourceLogs.resource.attributes(versionidx).value.stringValue;
                verifyTrue(testCase, matches(version_actual, versionpattern), ...
                    "Invalid version string: " + version_actual);

                nameidx = find(resourcekeys == "telemetry.sdk.name");
                verifyNotEmpty(testCase, nameidx);
                verifyEqual(testCase, results.resourceLogs.resource.attributes(nameidx).value.stringValue, 'opentelemetry');

                serviceidx = find(resourcekeys == "service.name");
                verifyNotEmpty(testCase, serviceidx);
                verifyEqual(testCase, results.resourceLogs.resource.attributes(serviceidx).value.stringValue, 'unknown_service');

                runtimeidx = find(resourcekeys == "process.runtime.name");
                verifyNotEmpty(testCase, runtimeidx);
                runtime_actual = results.resourceLogs.resource.attributes(runtimeidx).value.stringValue;
                verifyTrue(testCase, runtime_actual == "MATLAB" || runtime_actual == "MATLAB Runtime");

                runtimeversionidx = find(resourcekeys == "process.runtime.version");
                verifyNotEmpty(testCase, runtimeversionidx);
                runtimeversion_actual = results.resourceLogs.resource.attributes(runtimeversionidx).value.stringValue;
                verifyTrue(testCase, contains(runtimeversion_actual, "R" + digitsPattern + characterListPattern("ab")));
            end
        end

        function testSeverity(testCase)
            % testSeverity: different ways of setting severity
            loggername = "foo";
            logmessage = "bar";

            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, loggername);

            % set severity using text, number, and text with trailing
            % integer
            logseverity = {"info" 7 "warn2"};
            logseveritytext = ["info" "debug3" "warn2"];
            nseverity = length(logseverity);

            for i = 1:nseverity
                emitLogRecord(lg, logseverity{i}, logmessage);
            end

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, nseverity);
            for i = 1:nseverity
                resultsi = results{i};

                % check severity is set correctly
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.logRecords.severityText), upper(logseveritytext(i)));
            end
        end

        function testBody(testCase)
            % testBody: Body of different data types
            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "foo");

            % scalar
            scalarbody = {"abcde" 'fghi' 1 int32(5) true};
            scalarbodytype = ["string" "string" "double" "int" "bool"] + "Value";
            nscalar = length(scalarbody);
            % array
            arraybody = {["abcde" "fghij"] {'klmn'; 'opqr'} magic(3) int64(magic(4)) [true false true]};
            arraybodytype = ["string" "string" "double" "int" "bool"] + "Value";
            narray = length(arraybody);

            body = [scalarbody arraybody];
            nbody = nscalar + narray;
            for i = 1:nbody
                emitLogRecord(lg, "Debug", body{i});
            end

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, nbody);
            % check scalar results
            for i = 1:nscalar
                resultsi = results{i};

                % compare in strings which works for all types
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.logRecords.body.(scalarbodytype(i))), ...
                    string(scalarbody{i}));   
            end
            % check array results
            for i = 1:narray
                resultsi = results{nscalar+i};

                % compare in strings which works for all types
                verifyEqual(testCase, string({resultsi.resourceLogs.scopeLogs.logRecords.body.arrayValue.values.(arraybodytype(i))}), ...
                    string(reshape(arraybody{i},1,[])));
                % compare array size
                verifyNumElements(testCase, resultsi.resourceLogs.scopeLogs.logRecords.attributes, 1);
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.logRecords.attributes.key), ...
                    "Body.size");
                verifyEqual(testCase, [resultsi.resourceLogs.scopeLogs.logRecords.attributes.value.arrayValue.values.doubleValue], ...
                    size(arraybody{i}));
            end
        end

        function testBodyUnsupportedType(testCase)
            % testBody: Body of an unsupported type
            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "foo");

            nbody = 2;
            emitLogRecord(lg, "Warn", datetime("now"));   % datetime scalar
            emitLogRecord(lg, "Warn", hours(1:4));        % duration array

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, nbody);
            % check results
            for i = 1:nbody
                % body should be an empty string
                verifyEmpty(testCase, results{i}.resourceLogs.scopeLogs.logRecords.body.stringValue);   
            end
        end

        function testImplicitContext(testCase)
            % testImplicitContext: Test current trace and span IDs are recorded

            % start a span and make it current
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            sc = makeCurrent(sp); %#ok<*NASGU>

            % emit a log record
            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "baz");
            emitLogRecord(lg, "info", "qux");

            sc = [];
            endSpan(sp);

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            
            % check for two records: first a log and second a span
            verifyNumElements(testCase, results, 2);
            verifyTrue(testCase, isfield(results{1}, "resourceLogs"));
            verifyTrue(testCase, isfield(results{2}, "resourceSpans"));
            log = results{1};
            span = results{2};

            % check the trace and span IDs in the log record match those of 
            % the span
            verifyEqual(testCase, log.resourceLogs.scopeLogs.logRecords.traceId, ...
                span.resourceSpans.scopeSpans.spans.traceId);
            verifyEqual(testCase, log.resourceLogs.scopeLogs.logRecords.spanId, ...
                span.resourceSpans.scopeSpans.spans.spanId);
        end

        function testExplicitContext(testCase)
            % testExplicitContext: Explicitly specifying a context
            
            % start a span 
            tp = opentelemetry.sdk.trace.TracerProvider();
            tr = getTracer(tp, "foo");
            sp = startSpan(tr, "bar");
            spctxt = getSpanContext(sp);
            traceid = spctxt.TraceId;
            spanid = spctxt.SpanId;

            context = opentelemetry.context.Context;
            context = opentelemetry.trace.Context.insertSpan(context, sp);

            % emit a log record and specify context
            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "baz");
            emitLogRecord(lg, "info", "qux", Context=context);
            endSpan(sp);

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            log = results{1};

            % check the record trace and span IDs in the log record matches 
            % those of the span
            verifyEqual(testCase, string(log.resourceLogs.scopeLogs.logRecords.traceId), ...
                traceid);
            verifyEqual(testCase, string(log.resourceLogs.scopeLogs.logRecords.spanId), ...
                spanid);
        end


        function testTimestamp(testCase)
            % testTimestamp: specifying a timestamp
            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "foo");
            timestamp = datetime(2020,3,12,9,45,0);
            emitLogRecord(lg, "info", "bar", "Timestamp", timestamp);

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            verifyEqual(testCase, datetime(double(string(...
                results{1}.resourceLogs.scopeLogs.logRecords.timeUnixNano))/1e9, ...
                "convertFrom", "posixtime"), timestamp);  % convert from nanoseconds to seconds
        end

        function testAttributes(testCase)
            % testAttributes: specifying attributes

            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, "foo");
            attributes = dictionary(["stringscalar", "charrow", "singlescalar", ...
                "doublescalar", "int8scalar", "uint16scalar", "int32scalar", "uint32scalar", ...
                "int64scalar", "uint64scalar", "logicalscalar", "singlearray", ...
                "doublearray", "int8array", "uint16array", "int32array", "uint32array", ...
                "int64array", "uint64array", "logicalarray", "stringarray", ...
                "cellstr", "duration"], {"foo", 'bar', single(5), 10, int8(1), ...
                uint16(10), int32(10), uint32(20), int64(35), uint64(100), false, ...
                single([1 2; 3 4]), [2 3; 4 5], int8(-2:3), uint16(1:5), ...
                int32(1:6), uint32((15:18).'), int64(reshape(1:4,2,1,2)), ...
                uint64([100 200; 300 400]), [true false true], ["foo", "bar", "quux", "quz"], ...
                {'foo', 'bar', 'quux', 'quz'}, hours(2)});
            emitLogRecord(lg, "warn", "bar", Attributes=attributes);

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);

            attrkeys = string({results{1}.resourceLogs.scopeLogs.logRecords.attributes.key});

            % scalars
            % string and char
            textscalars = ["stringscalar" "charrow"];
            for i = 1:length(textscalars)
                stringscidx = find(attrkeys == textscalars(i));
                verifyNotEmpty(testCase, stringscidx);
                verifyEqual(testCase, string(results{1}.resourceLogs.scopeLogs.logRecords.attributes(stringscidx).value.stringValue), ...
                    string(attributes{textscalars(i)}));
            end

            % floating point scalars
            floatscalars = ["single" "double"] + "scalar";
            for i = 1:length(floatscalars)
                floatscidx = find(attrkeys == floatscalars(i));
                verifyNotEmpty(testCase, floatscidx);
                verifyEqual(testCase, results{1}.resourceLogs.scopeLogs.logRecords.attributes(floatscidx).value.doubleValue, ...
                    double(attributes{floatscalars(i)}));
            end

            % integer scalars
            intscalars = ["int8" "uint16" "int32" "uint32" "int64" "uint64"] + "scalar";
            for i = 1:length(intscalars)
                intscidx = find(attrkeys == intscalars(i));
                verifyNotEmpty(testCase, intscidx);
                verifyEqual(testCase, results{1}.resourceLogs.scopeLogs.logRecords.attributes(intscidx).value.intValue, ...
                    char(string(attributes{intscalars(i)})));
            end

            % logical scalar
            logicalscidx = find(attrkeys == "logicalscalar");
            verifyNotEmpty(testCase, logicalscidx);
            verifyFalse(testCase, results{1}.resourceLogs.scopeLogs.logRecords.attributes(logicalscidx).value.boolValue);

            % arrays
            % floating point arrays
            floatarrays = ["single" "double"] + "array";
            for i = 1:length(floatarrays)
                floataridx = find(attrkeys == floatarrays(i));
                verifyNotEmpty(testCase, floataridx);
                verifyEqual(testCase, [results{1}.resourceLogs.scopeLogs.logRecords.attributes(floataridx).value.arrayValue.values.doubleValue], ...
                    double(reshape(attributes{floatarrays(i)}, 1, [])));

                floatszidx = find(attrkeys == floatarrays(i) + ".size");
                verifyNotEmpty(testCase, floatszidx);
                verifyEqual(testCase, [results{1}.resourceLogs.scopeLogs.logRecords.attributes(floatszidx).value.arrayValue.values.doubleValue], ...
                    size(attributes{floatarrays(i)}));
            end

            % integer arrays
            intarrays = ["int8" "uint16" "int32" "uint32" "int64" "uint64"] + "array";
            for i = 1:length(intarrays)
                intaridx = find(attrkeys == intarrays(i));
                verifyNotEmpty(testCase, intaridx);
                verifyEqual(testCase, double(string({results{1}.resourceLogs.scopeLogs.logRecords.attributes(intaridx).value.arrayValue.values.intValue})), ...
                    double(reshape(attributes{intarrays(i)},1,[])));

                intszidx = find(attrkeys == intarrays(i) + ".size");
                verifyNotEmpty(testCase, intszidx);
                verifyEqual(testCase, [results{1}.resourceLogs.scopeLogs.logRecords.attributes(intszidx).value.arrayValue.values.doubleValue], ...
                    size(attributes{intarrays(i)}));
            end           

            logicalaridx = find(attrkeys == "logicalarray");
            verifyNotEmpty(testCase, logicalaridx);
            verifyEqual(testCase, [results{1}.resourceLogs.scopeLogs.logRecords.attributes(logicalaridx).value.arrayValue.values.boolValue], ...
                reshape(attributes{"logicalarray"},1,[]));

            logicalszidx = find(attrkeys == "logicalarray.size");
            verifyNotEmpty(testCase, logicalszidx);
            verifyEqual(testCase, [results{1}.resourceLogs.scopeLogs.logRecords.attributes(logicalszidx).value.arrayValue.values.doubleValue], ...
                size(attributes{"logicalarray"}));

            % text arrays
            textarrays = ["stringarray" "cellstr"];
            for i = 1:length(textarrays)
                stringaridx = find(attrkeys == textarrays(i));
                verifyNotEmpty(testCase, stringaridx);
                verifyEqual(testCase, string({results{1}.resourceLogs.scopeLogs.logRecords.attributes(stringaridx).value.arrayValue.values.stringValue}), ...
                    string(attributes{textarrays(i)}));

                stringszidx = find(attrkeys == textarrays(i) + ".size");
                verifyNotEmpty(testCase, stringszidx);
                verifyEqual(testCase, [results{1}.resourceLogs.scopeLogs.logRecords.attributes(stringszidx).value.arrayValue.values.doubleValue], ...
                    size(attributes{textarrays(i)}));
            end

            % duration, not supported
            durationidx = find(attrkeys == "duration");
            verifyEmpty(testCase, durationidx);
        end

        function testSeverityFunctions(testCase)
            % testSeverityFunctions: trace, debug, info, warn, error, fatal
            loggername = "foo";
            logmessage = "bar";

            lp = opentelemetry.sdk.logs.LoggerProvider();
            lg = getLogger(lp, loggername);

            funcs = {@lg.trace, @lg.debug, @lg.info, @lg.warn, @lg.error, @lg.fatal};
            nfuncs = length(funcs);
            logseverity = ["trace" "debug" "info" "warn" "error" "fatal"];

            for i = 1:nfuncs
                funcs{i}(logmessage);
            end

            % perform test comparisons
            forceFlush(lp, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);
            verifyNumElements(testCase, results, nfuncs);
            for i = 1:nfuncs
                resultsi = results{i};

                % check logger name, log body and severity, trace and span IDs 
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.scope.name), loggername);
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.logRecords.severityText), upper(logseverity(i)));
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.logRecords.body.stringValue), logmessage);
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.logRecords.traceId), "");
                verifyEqual(testCase, string(resultsi.resourceLogs.scopeLogs.logRecords.spanId), "");
            end
        end

        function testGetSetLoggerProvider(testCase)
            % testGetSetLoggerProvider: setting and getting global instance of LoggerProvider
            customkey = "quux";
            customvalue = 1;
            proc = opentelemetry.sdk.logs.SimpleLogRecordProcessor;
            lp = opentelemetry.sdk.logs.LoggerProvider(proc, ...
                "Resource", dictionary(customkey, customvalue));  % specify an arbitrary resource as an identifier
            setLoggerProvider(lp);
            clear("lp");

            loggername = "foo";
            logseverity = "warn";
            logmessage = "bar";
            lg = opentelemetry.logs.getLogger(loggername);
            emitLogRecord(lg, logseverity, logmessage);

            % perform test comparisons
            opentelemetry.sdk.common.Cleanup.forceFlush(...
                opentelemetry.logs.Provider.getLoggerProvider, testCase.ForceFlushTimeout);
            results = readJsonResults(testCase);

            % check log record, and check its resource to identify the
            % correct LoggerProvider has been used
            verifyNotEmpty(testCase, results);

            verifyEqual(testCase, string(results{1}.resourceLogs.scopeLogs.logRecords.severityText), upper(logseverity));
            verifyEqual(testCase, string(results{1}.resourceLogs.scopeLogs.logRecords.body.stringValue), logmessage);
            verifyEqual(testCase, string(results{1}.resourceLogs.scopeLogs.scope.name), loggername);

            resourcekeys = string({results{1}.resourceLogs.resource.attributes.key});
            idx = find(resourcekeys == customkey);
            verifyNotEmpty(testCase, idx);
            verifyEqual(testCase, results{1}.resourceLogs.resource.attributes(idx).value.doubleValue, customvalue);
        end
    end
end