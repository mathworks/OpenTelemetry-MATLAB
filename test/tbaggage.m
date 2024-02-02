classdef tbaggage < matlab.unittest.TestCase
    % tests for creating and manipulating baggage object

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        BaggageKeys
        BaggageValues
        BaggageHeaders
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            otelroot = getenv("OPENTELEMETRY_MATLAB_INSTALL");

            % set up path
            if ~isempty(otelroot)
                testCase.applyFixture(matlab.unittest.fixtures.PathFixture(otelroot));
            end

            testCase.BaggageKeys = ["userId", "serverNode", "isProduction"];
            testCase.BaggageValues = ["alice", "DF28", "false"];
        end
    end

    methods (Test)
        function testCreate(testCase)
            % testCreate: creating a baggage object

            % create a baggage
            baggagekeys = testCase.BaggageKeys;
            baggagevalues = testCase.BaggageValues;
            bag = opentelemetry.baggage.Baggage(dictionary(baggagekeys, baggagevalues));
            bagentries = bag.Entries;

            % verify same baggage keys (can be in different order), and their values
            verifyEmpty(testCase, setxor(keys(bagentries), baggagekeys));
            verifyEqual(testCase, bagentries(baggagekeys), baggagevalues);
        end

        function testSetEntries(testCase)
            % testSetEntries: setting baggage entries

            % create a baggage
            baggagekeys = testCase.BaggageKeys;
            baggagevalues = testCase.BaggageValues;
            bag = opentelemetry.baggage.Baggage(dictionary(baggagekeys, baggagevalues));

            % add a new key-value pair and modify a value
            newkeys = ["location" "serverNode"];
            newvalues = ["Natick" "DA45"];
            bag = setEntries(bag, newkeys, newvalues);
            bagentries = bag.Entries;

            [combinedkeys, ia, ib] = union(newkeys, baggagekeys, "stable");
            combinedvalues = [newvalues(ia) baggagevalues(ib)];
            verifyEmpty(testCase, setxor(keys(bagentries), combinedkeys));
            verifyEqual(testCase, bagentries(combinedkeys), combinedvalues);
        end

        function testDeleteEntries(testCase)
            % testDeleteEntries: deleting baggage entries

            % create a baggage
            baggagekeys = testCase.BaggageKeys;
            baggagevalues = testCase.BaggageValues;
            bag = opentelemetry.baggage.Baggage(dictionary(baggagekeys, baggagevalues));

            % delete 2 keys: one valid and one nonexistent
            deletekeys = ["userId" "location"];
            bag = deleteEntries(bag, deletekeys);
            bagentries = bag.Entries;

            % verify updated baggage keys and values
            [newkeys, ia] = setdiff(baggagekeys, deletekeys);
            verifyEmpty(testCase, setxor(keys(bagentries), newkeys));
            verifyEqual(testCase, bagentries(newkeys), baggagevalues(ia));
        end

        function testModify(testCase)
            % testModify: changing the Entries property of baggage

            % create a baggage
            baggagekeys = testCase.BaggageKeys;
            baggagevalues = testCase.BaggageValues;
            bag = opentelemetry.baggage.Baggage(dictionary(baggagekeys, baggagevalues));

            % modify the Entries property
            newkeys = ["userId", "location", "serverNode"];
            newvalues = ["alice", "Natick", "DF25"];
            bag.Entries = dictionary(newkeys, newvalues);
            bagentries = bag.Entries;

            % verify the modified entries
            verifyEmpty(testCase, setxor(keys(bagentries), newkeys));
            verifyEqual(testCase, bagentries(newkeys), newvalues);
        end
    end
end