classdef AutoTrace < handle
    % Automatic instrumentation with OpenTelemetry tracing.

    % Copyright 2024-2026 The MathWorks, Inc.

    properties (SetAccess=private)
        StartFunction function_handle   % entry function
        InstrumentedFiles string        % list of M-files that are auto-instrumented 
    end

    properties (Access=private)    
        Instrumentor (1,1) opentelemetry.autoinstrument.AutoTraceInstrumentor  % helper object
    end

    methods
        function obj = AutoTrace(startfun, options)
            % AutoTrace    Automatic instrumentation with OpenTelemetry tracing
            %    AT = OPENTELEMETRY.AUTOINSTRUMENT.AUTOTRACE(FUN) where FUN 
            %    is a function handle, automatically instruments the function 
            %    and all the functions in the same file, as well as their dependencies.
            %    For each function, a span is automatically started and made 
            %    current at the beginning, and ended at the end. Returns an
            %    object AT. When AT is cleared or goes out-of-scope, automatic 
            %    instrumentation will stop and the functions will no longer 
            %    be instrumented.
            %
            %    If called in a deployable archive (CTF file), all M-files 
            %    included in the CTF will be instrumented.
            %
            %    AT = OPENTELEMETRY.AUTOINSTRUMENT.AUTOTRACE(FUN, NAME1, VALUE1, 
            %    NAME2, VALUE2, ...) specifies optional name-value pairs. 
            %    Supported options are:
            %       "AdditionalFiles"   - List of additional file names to 
            %                             include. Specifying additional files 
            %                             are useful in cases when automatic 
            %                             dependency detection failed to include them. 
            %                             For example, MATLAB Toolbox functions 
            %                             authored by MathWorks are excluded by default.
            %       "ExcludeFiles"      - List of file names to exclude
            %       "AutoDetectFiles"   - Whether to automatically include dependencies 
            %                             of FUN, specified as a logical scalar. 
            %                             Default value is true.
            %       "TracerName"        - Specifies the name of the tracer 
            %                             the automatic spans are generated from
            %       "TracerVersion"     - The tracer version
            %       "TracerSchema"      - The tracer schema
            %       "Attributes"        - Add attributes to all the automatic spans. 
            %                             Attributes must be specified as a dictionary.
            %       "SpanKind"          - Span kind of the automatic spans
            arguments
                startfun (1,1) function_handle
                options.TracerName {mustBeTextScalar} = "AutoTrace"
                options.TracerVersion {mustBeTextScalar} = ""
                options.TracerSchema {mustBeTextScalar} = ""
                options.SpanKind {mustBeTextScalar}
                options.Attributes {mustBeA(options.Attributes, "dictionary")}
                options.ExcludeFiles {mustBeText}
                options.AdditionalFiles {mustBeText}
                options.AutoDetectFiles (1,1) {mustBeNumericOrLogical} = true
            end
            % check for anonymous function
            fs = functions(startfun);
            if fs.type == "anonymous"                  
                error("opentelemetry:autoinstrument:AutoTrace:AnonymousFunction", ...
                    "Anonymous functions are not supported.");
            end
            obj.StartFunction = startfun;
            startfunname = func2str(startfun);
            startfunname = processFileInput(startfunname);   % validate startfun
            if options.AutoDetectFiles
                if isdeployed
                    % matlab.codetools.requiredFilesAndProducts is not
                    % deployable. Instead instrument all files under CTFROOT
                    fileinfo = [reshape(dir(fullfile(ctfroot, "**", "*.m")), [], 1); ...
                        reshape(dir(fullfile(ctfroot, "**", "*.mlx")), [], 1)];
                    files = fullfile(string({fileinfo.folder}), string({fileinfo.name}));

                    % filter out internal files in the toolbox directory
                    files = files(~startsWith(files, fullfile(ctfroot, "toolbox")));
                else
                    %#exclude matlab.codetools.requiredFilesAndProducts
                    files = string(matlab.codetools.requiredFilesAndProducts(startfunname));
                    
                    % keep only .m and .mlx files. Filter out everything else
                    [~,~,fext] = fileparts(files);
                    files = files(ismember(fext, [".m" ".mlx"]));
                end
            else
                % only include the input file, not its dependencies
                files = startfunname;
            end
            % add extra files, this is intended for files
            % matlab.codetools.requiredFilesAndProducts somehow missed
            if isfield(options, "AdditionalFiles")   
                incinput = string(options.AdditionalFiles);
                incfiles = []; 
                for i = 1:numel(incinput)
                    % validate additional file
                    incfiles = [incfiles; processFileOrFolderInput(incinput(i))];   %#ok<AGROW> 
                end
                files = union(files, incfiles);
            end

            % make sure files are unique
            files = unique(files);

            % filter out excluded files
            if isfield(options, "ExcludeFiles")   
                excinput = string(options.ExcludeFiles);
                excfiles = [];
                for i = 1:numel(excinput)
                    % validate exclude file
                    excfiles = [excfiles; processFileOrFolderInput(excinput(i))];   %#ok<AGROW>
                end
                files = setdiff(files, excfiles);
            end
            % filter out OpenTelemetry files, in case manual
            % instrumentation is also used
            files = files(~contains(files, ["+opentelemetry" "+libmexclass"]));

            for i = 1:length(files)
                currfile = files(i);
                if currfile ==""    % ignore empties
                    continue
                end
                obj.Instrumentor.instrument(currfile, options);
                obj.InstrumentedFiles(end+1,1) = currfile;
            end
        end

        function delete(obj)
            obj.Instrumentor.cleanup(obj.InstrumentedFiles);
        end

        function varargout = beginTrace(obj, varargin)
            % beginTrace    Run the auto-instrumented function
            %    [OUT1, OUT2, ...] = BEGINTRACE(AT, IN1, IN2, ...) calls the 
            %    instrumented function with error handling. In case of
            %    error, all running spans will end and the last span will
            %    set to an "Error" status. The instrumented function is
            %    called with the synax [OUT1, OUT2, ...] = FUN(IN1, IN2, ...)
            %
            %    See also OPENTELEMETRY.AUTOINSTRUMENT.AUTOTRACE/HANDLEERROR
            try
                varargout = cell(1,nargout);
                [varargout{:}] = feval(obj.StartFunction, varargin{:});
            catch ME
                handleError(obj, ME);
            end
        end

        function handleError(obj, ME)
            % handleError    Perform cleanup in case of an error
            %    HANDLEERROR(AT, ME) performs cleanup by ending all running
            %    spans and their corresponding scopes. Rethrow the
            %    exception ME.
            if ~isempty(obj.Instrumentor.Spans)
                errorspan = obj.Instrumentor.Spans(end); 
                setStatus(errorspan, "Error", ME.message);
                recordException(errorspan, ME);
                for i = length(obj.Instrumentor.Spans):-1:1
                    obj.Instrumentor.Spans(i) = [];
                    obj.Instrumentor.Scopes(i) = [];
                end
            end
            rethrow(ME);
        end
    end

    
end

% check input file is valid
function f = processFileInput(f)
f = string(f);   % force into a string
[~,~,fext] = fileparts(f);  % check file extension
filetype = exist(f, "file");  % check file type
if filetype == 2 && ismember(fext, ["" ".m" ".mlx"])
    f = string(which(f));
else
    if exist(f, "builtin")
        error("opentelemetry:autoinstrument:AutoTrace:BuiltinFunction", ...
            replace(f, "\", "\\") + " is a builtin function and is not supported.");
    else
        error("opentelemetry:autoinstrument:AutoTrace:InvalidMFile", ...
            replace(f, "\", "\\") + " is not found or is not a valid MATLAB file with a .m or .mlx extension.");
    end
end
end

% check input file or folder is valid
function f = processFileOrFolderInput(f)
f = string(f);   % force into a string
if isfolder(f)
    % expand the directory
    mfileinfo = dir(fullfile(f, "*.m"));
    mfiles = fullfile(string({mfileinfo.folder}), string({mfileinfo.name}));
    mlxfileinfo = dir(fullfile(f, "*.mlx"));
    mlxfiles = fullfile(string({mlxfileinfo.folder}), string({mlxfileinfo.name}));
    f = [mfiles(:); mlxfiles(:)];
else
    % file
    f = processFileInput(f);
end
end
