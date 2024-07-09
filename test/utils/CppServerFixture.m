classdef CppServerFixture < matlab.unittest.fixtures.Fixture
    % CppServerFixture starts and terminates a C++ server used in 
    % examples/webread 

    % Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        ServerFile (1,1) string
    end

    properties(Access = private)        
        TestCase
    end

    properties(Constant)
        ServerName = "webread_example_server"
    end

    methods
        function fixture = CppServerFixture(serverfile, testCase)
            fixture.ServerFile = string(serverfile);
            fixture.TestCase = testCase;
        end

        function setup(fixture)
            system(fixture.ServerFile + '&');
        end

        function teardown(fixture)
            terminateProcess(fixture.TestCase, fixture.ServerName);
            closeWindow(fixture.TestCase);
        end
    end

    methods (Hidden, Access=protected)
        function bool = isCompatible(fixture, other)
            bool = (fixture.ServerFile == other.ServerFile);
        end
    end
end
