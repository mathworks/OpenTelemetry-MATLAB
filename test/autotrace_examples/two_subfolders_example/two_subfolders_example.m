function x = two_subfolders_example
% Example code for testing auto instrumentation, with helper functions
% in a two subfolders

% Copyright 2025 The MathWorks, Inc.

x = 10;
x = subfolder_helper1_1(x);
x = subfolder_helper1_2(x);
x = subfolder_helper2_1(x);
x = subfolder_helper2_2(x);
x = subfolder_helper2_3(x);

