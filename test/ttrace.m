function tests = ttrace
% tests for traces and spans
%
% Copyright 2023 The MathWorks, Inc.

tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% file definitions
otelcolroot = getenv("OPENTELEMETRY_COLLECTOR_INSTALL");
testCase.TestData.otelconfigfile = "otelcol_config.yml";
testCase.TestData.otelroot = getenv("OPENTELEMETRY_MATLAB_INSTALL");
testCase.TestData.jsonfile = "myoutput.json";
testCase.TestData.pidfile = "testoutput.txt";

% process definitions
testCase.TestData.otelcol = fullfile(otelcolroot, "otelcol");
if ispc
   testCase.TestData.list = @(name)"tasklist /fi ""IMAGENAME eq " + name + ".exe""";
   testCase.TestData.readlist = @(file)readtable(file, "VariableNamingRule", "preserve", "NumHeaderLines", 3, "MultipleDelimsAsOne", true, "Delimiter", " ");
   testCase.TestData.extractPid = @(table)table.Var2;
   windows_killroot = string(getenv("WINDOWS_KILL_INSTALL"));
   testCase.TestData.sigint = @(id)fullfile(windows_killroot,"windows-kill") + " -SIGINT " + id;
   testCase.TestData.sigterm = @(id)"taskkill /pid " + id;
elseif isunix && ~ismac
   testCase.TestData.list = @(name)"ps -C " + name;
   testCase.TestData.readlist = @readtable;
   testCase.TestData.extractPid = @(table)table.PID;
   testCase.TestData.sigint = @(id)"kill " + id;  % kill sends a SIGTERM instead of SIGINT but turns out this is sufficient to terminate OTEL collector on Linux
   testCase.TestData.sigterm = @(id)"kill " + id;
end

% set up path
addpath(testCase.TestData.otelroot);

% remove temporary files if present
if exist(testCase.TestData.jsonfile, "file")
    delete(testCase.TestData.jsonfile);
end
if exist(testCase.TestData.pidfile, "file")
    delete(testCase.TestData.pidfile);
end
end

function setup(testCase)
% start collector
system(testCase.TestData.otelcol + " --config " + testCase.TestData.otelconfigfile + '&');
pause(1);   % give a little time for Collector to start up
end

function teardown(testCase)
% On Windows, a command prompt has popped up, remove it as clean up
if ispc
    system(testCase.TestData.list("cmd") + "  > " + testCase.TestData.pidfile);
    tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
    pid = tbl.Var2(end-1);
    system(testCase.TestData.sigterm(pid));
end

delete(testCase.TestData.jsonfile);
delete(testCase.TestData.pidfile);
end

function jsonresults = gatherjson(testCase)

system(testCase.TestData.list("otelcol") + " > " + testCase.TestData.pidfile);

tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
pid = testCase.TestData.extractPid(tbl);
system(testCase.TestData.sigint(pid));

% check if kill succeeded as it can sporadically fail
system(testCase.TestData.list("otelcol") + " > " + testCase.TestData.pidfile);
tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
pid = testCase.TestData.extractPid(tbl);
retry = 0;
% sometimes kill will fail with a RuntimeError: windows-kill-library: ctrl-routine:findAddress:checkAddressIsNotNull 
% in that case, retry up to 3 times
while ~isempty(pid) && retry < 3
    system(testCase.TestData.sigint(pid));
    tbl = testCase.TestData.readlist(testCase.TestData.pidfile);
    pid = testCase.TestData.extractPid(tbl);
    retry = retry + 1;
end

pause(1);
assert(exist(testCase.TestData.jsonfile, "file"));

fid = fopen(testCase.TestData.jsonfile);
raw = fread(fid, inf);
str = cellstr(strsplit(char(raw'),'\n'));
% discard the last cell, which is empty
str(end) = [];
fclose(fid);
jsonresults = cellfun(@jsondecode,str,"UniformOutput",false);
end

%% testBasic: names, default spankind and status, default resource
function testBasic(testCase)

tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "foo");
sp = startSpan(tr, "bar");
pause(1);
endSpan(sp);

% perform test comparisons
results = gatherjson(testCase);
results = results{1};

% check span and tracer names
verifyEqual(testCase, results.resourceSpans.scopeSpans.spans.name, 'bar');
verifyEqual(testCase, results.resourceSpans.scopeSpans.scope.name, 'foo');

% check spankind and status
verifyEqual(testCase, results.resourceSpans.scopeSpans.spans.kind, 1);   % internal
verifyEmpty(testCase, fieldnames(results.resourceSpans.scopeSpans.spans.status));   % status unset

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

%% testParent: parent and children relationship
function testParent(testCase)

tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "tracer");
sp = startSpan(tr, "parent");
scope = makeCurrent(sp);
sp1 = startSpan(tr, "with parent");
clear("sp1");
clear("scope")
sp2 = startSpan(tr, "without parent");
clear("sp2");
clear("sp");

% perform test comparisons
results = gatherjson(testCase);

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

%% testSpanKind: specifying SpanKind
function testSpanKind(testCase)

tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "tracer");
sp1 = startSpan(tr, "server", "SpanKind", "server");
endSpan(sp1);
sp2 = startSpan(tr, "consumer", "SpanKind", "consumer");
endSpan(sp2);

% perform test comparisons
results = gatherjson(testCase);
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.name, 'server');
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.kind, 2);   % server has a enum id of 2
verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.name, 'consumer');
verifyEqual(testCase, results{2}.resourceSpans.scopeSpans.spans.kind, 5);   % consumer has a enum id of 5
end

%% testAttributes: specifying attributes when starting spans
function testAttributes(testCase)

tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "tracer");
% TODO: string scalar is current broken, and string array not yet
% implemented
attributes = dictionary(["doublescalar", "int32scalar", "uint32scalar", "int64scalar", ...
    "logicalscalar", "doublearray", "int32array", "uint32array", "int64array", ...
    "logicalarray"], {10, int32(10), uint32(20), int64(35), false, [2 3; 4 5], ...
    int32(1:6), uint32((15:18).'), int64(reshape(1:4,2,1,2)), [true false true]});
sp1 = startSpan(tr, "span", "Attributes", attributes);
endSpan(sp1);

% perform test comparisons
results = gatherjson(testCase);

attrkeys = string({results{1}.resourceSpans.scopeSpans.spans.attributes.key});

% scalars
doublescidx = find(attrkeys == "doublescalar");
verifyNotEmpty(testCase, doublescidx);
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(doublescidx).value.doubleValue, 10);

i32scidx = find(attrkeys == "int32scalar");
verifyNotEmpty(testCase, i32scidx);
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(i32scidx).value.intValue, '10');

u32scidx = find(attrkeys == "uint32scalar");
verifyNotEmpty(testCase, u32scidx);
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(u32scidx).value.intValue, '20');

i64scidx = find(attrkeys == "int64scalar");
verifyNotEmpty(testCase, i64scidx);
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(i64scidx).value.intValue, '35');

logicalscidx = find(attrkeys == "logicalscalar");
verifyNotEmpty(testCase, logicalscidx);
verifyFalse(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(logicalscidx).value.boolValue);

% arrays
doublearidx = find(attrkeys == "doublearray");
verifyNotEmpty(testCase, doublearidx);
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doublearidx).value.arrayValue.values.doubleValue], ...
    reshape([2 3; 4 5], 1, []));

doubleszidx = find(attrkeys == "doublearray.size");
verifyNotEmpty(testCase, doubleszidx);
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doubleszidx).value.arrayValue.values.doubleValue], [2 2]);

i32aridx = find(attrkeys == "int32array");
verifyNotEmpty(testCase, i32aridx);
verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(i32aridx).value.arrayValue.values.intValue})), 1:6);

i32szidx = find(attrkeys == "int32array.size");
verifyNotEmpty(testCase, i32szidx);
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(i32szidx).value.arrayValue.values.doubleValue], [1 6]);

u32aridx = find(attrkeys == "uint32array");
verifyNotEmpty(testCase, u32aridx);
verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(u32aridx).value.arrayValue.values.intValue})), 15:18);

u32szidx = find(attrkeys == "uint32array.size");
verifyNotEmpty(testCase, u32szidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(u32szidx).value.arrayValue.values.doubleValue], [4 1]);

i64aridx = find(attrkeys == "int64array");
verifyNotEmpty(testCase, i64aridx);
verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(i64aridx).value.arrayValue.values.intValue})), 1:4);

i64szidx = find(attrkeys == "int64array.size");
verifyNotEmpty(testCase, i64szidx);
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(i64szidx).value.arrayValue.values.doubleValue], [2 1 2]);

logicalaridx = find(attrkeys == "logicalarray");
verifyNotEmpty(testCase, logicalaridx);
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(logicalaridx).value.arrayValue.values.boolValue], [true false true]);

logicalszidx = find(attrkeys == "logicalarray.size");
verifyNotEmpty(testCase, logicalszidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(logicalszidx).value.arrayValue.values.doubleValue], [1 3]);
end

%% testSetAttributes: specifying attributes using SetAttributes method
function testSetAttributes(testCase)
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "foo");
sp = startSpan(tr, "bar");
% Name-value pairs
setAttributes(sp, "doublescalar", 15, "int32array", reshape(int32(1:6),2,3));
% dictionary
attributes = dictionary(["doublearray", "int64scalar"], {reshape(10:13,1,2,2), int64(155)});
setAttributes(sp, attributes);
endSpan(sp);

% perform test comparisons
results = gatherjson(testCase);

attrkeys = string({results{1}.resourceSpans.scopeSpans.spans.attributes.key});

doublescidx = find(attrkeys == "doublescalar");
verifyNotEmpty(testCase, doublescidx); 
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(doublescidx).value.doubleValue, 15);

i32aridx = find(attrkeys == "int32array");
verifyNotEmpty(testCase, i32aridx);
verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.attributes(i32aridx).value.arrayValue.values.intValue})), 1:6);

i32szidx = find(attrkeys == "int32array.size");
verifyNotEmpty(testCase, i32szidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(i32szidx).value.arrayValue.values.doubleValue], [2 3]);

doublearidx = find(attrkeys == "doublearray");
verifyNotEmpty(testCase, doublearidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doublearidx).value.arrayValue.values.doubleValue], 10:13);

doubleszidx = find(attrkeys == "doublearray.size");
verifyNotEmpty(testCase, doubleszidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.attributes(doubleszidx).value.arrayValue.values.doubleValue], [1 2 2]);

i64scidx = find(attrkeys == "int64scalar");
verifyNotEmpty(testCase, i64scidx); 
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.attributes(i64scidx).value.intValue, '155');
end

%% testEvents: adding events
function testEvents(testCase)
tp = opentelemetry.sdk.trace.TracerProvider();
tr = getTracer(tp, "foo");
sp = startSpan(tr, "bar");
% Name-value pairs
addEvent(sp, "baz", "doublescalar", 5, "int32array", reshape(int32(1:6),2,3));
% dictionary
attributes = dictionary(["doublearray", "int64scalar"], {reshape(1:4,1,2,2), int64(350)});
addEvent(sp, "quux", attributes);
endSpan(sp);

results = gatherjson(testCase);

% event 1
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(1).name, 'baz');

event1keys = string({results{1}.resourceSpans.scopeSpans.spans.events(1).attributes.key});

doublescidx = find(event1keys == "doublescalar");
verifyNotEmpty(testCase, doublescidx); 
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(1).attributes(doublescidx).value.doubleValue, 5);

i32aridx = find(event1keys == "int32array");
verifyNotEmpty(testCase, i32aridx);
verifyEqual(testCase, double(string({results{1}.resourceSpans.scopeSpans.spans.events(1).attributes(i32aridx).value.arrayValue.values.intValue})), 1:6);

i32szidx = find(event1keys == "int32array.size");
verifyNotEmpty(testCase, i32szidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.events(1).attributes(i32szidx).value.arrayValue.values.doubleValue], [2 3]);

% event 2
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(2).name, 'quux');

event2keys = string({results{1}.resourceSpans.scopeSpans.spans.events(2).attributes.key});

doublearidx = find(event2keys == "doublearray");
verifyNotEmpty(testCase, doublearidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(doublearidx).value.arrayValue.values.doubleValue], 1:4);

doubleszidx = find(event2keys == "doublearray.size");
verifyNotEmpty(testCase, doubleszidx); 
verifyEqual(testCase, [results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(doubleszidx).value.arrayValue.values.doubleValue], [1 2 2]);

i64scidx = find(event2keys == "int64scalar");
verifyNotEmpty(testCase, i64scidx); 
verifyEqual(testCase, results{1}.resourceSpans.scopeSpans.spans.events(2).attributes(i64scidx).value.intValue, '350');
end
