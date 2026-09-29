# MATLAB Production Server (MPS) AutoTrace Example
This example shows how to use an AutoTrace wrapper function to automatically instrument MATLAB code deployed to MATLAB Production Server. This is an easy way to profile your functions in deployment without needing to make any changes to the original function code. 

To use the wrapper, include it as an additional deployed function when packaging the CTF containing your function code. Once deployed, functions can be invoked normally to run without tracing, or through the *autotrace_wrapper* to run with tracing. 

For example, if you would normally call your deployed function *my_function* with arguments 3, 2, 1, and "linear" as follows:
```
curl http://localhost:9910/MyFunction/my_function -H "Content-Type: application/json" -X POST -d "{'nargout':1,'rhs':[3, 2, 1, 'linear']}"
```
To run the same call with autotracing, call *autotrace_wrapper* with the function name as the first argument, followed by all other arguments:
```
curl http://localhost:9910/MyFunction/autotrace_wrapper -H "Content-Type: application/json" -X POST -d "{'nargout':1,'rhs':['my_function', 3, 2, 1, 'linear']}"
```



## Testing the Example
1. Start an instance of [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector).
2. Generate and test a .ctf archive using the [testing interface](https://www.mathworks.com/help/compiler_sdk/mps_dev_test/test-web-request-handler.html) in the Production Server Compiler app.
      1. In MATLAB, navigate to the example directory.
      2. Start the Production Server Compiler app.
         ```
         productionServerCompiler
         ```
      3. In the app, select Type as "Deployable Archive (.ctf)", and add my_function.m  and autotrace_wrapper.m as exported functions.
      4. Specify "MyFunction" as the archive name.
      5. Click on the "Test Client" button.
      6. Ensure the port is 9910, then start the test.
      7. Using a command prompt, send a cURL request to call my_function through the autotrace_wrapper function.
         ```
         curl http://localhost:9910/MyFunction/autotrace_wrapper -H "Content-Type: application/json" -X POST -d "{'nargout':1,'rhs':['my_function', 3, 2, 1, 'linear']}"
         ```
      8. Check for expected spans in the OpenTelemetry Collector or in a specified tracing backend.

**NOTE:** You may need to manually add your OpenTelemetry-matlab installation as "Files Required for Archive to Run" during packaging, as certain file dependencies may not be automatically detected by dependency analysis. Failing to include these dependencies can result in errors when running the generated CTF on a different machine.

## Deploying the Example
1. If testing works, proceed to deploy the example. [Create](https://www.mathworks.com/help/mps/server/creating-a-server.html) and [start](https://www.mathworks.com/help/mps/qs/starting-and-stopping.html) a MATLAB Production Server instance.
2. [Deploy](https://www.mathworks.com/help/mps/qs/share-a-ctf-archive-on-the-server-instance.html) archive MyFunction.ctf to the server instance by copying to the auto_deploy directory.
3. Using a command prompt, send a cURL request to call my_function through the autotrace_wrapper function.
   ```
   curl http://localhost:9910/MyFunction/autotrace_wrapper -H "Content-Type: application/json" -X POST -d "{'nargout':1,'rhs':['my_function', 3, 2, 1, 'linear']}"
   ```
4. Check for expected spans in the OpenTelemetry Collector or in a specified tracing backend.


