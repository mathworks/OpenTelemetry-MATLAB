function y = matfile_example
% Example code for testing auto instrumentation, which loads a .mat file

% Copyright 2025 The MathWorks, Inc.

load("mymagic", "x");
y = sum(x);