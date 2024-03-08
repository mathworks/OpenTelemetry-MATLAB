# parfor Example
This example can only run if Parallel Computing Toolbox is installed. It shows how to instrument a parfor loop using spans. parfor is a function in Parallel Computing Toolbox that implements a parallel for-loop. It performs its iterations in parallel by sending them to workers in a parallel pool. The instrumented code loops through a series of random matrices and compute their maximum eigenvalue.
* At the beginning of the first run, initialization is necessary to create and store a global tracer provider.
* Initialization is also necessary in the parfor block, as this code is run in separate workers and each worker needs to run the initialization during the first run.
* A span is created both before and inside the parfor block.
* To have all the spans form a single trace, context has to be passed explicitly into the parfor block.

## Running the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Start MATLAB. 
3. Make sure Parallel Computing Toolbox is installed by typing the command "ver parallel".
3. Ensure the installation directory of OpenTelemetry-matlab is on the MATLAB path.
4. Run parfor\_example. By default, MATLAB automatically opens a parallel pool of workers on your local machine.
5. Run parfor\_example again. The second run should be faster than the first run because the parallel pool takes some time to start up.
