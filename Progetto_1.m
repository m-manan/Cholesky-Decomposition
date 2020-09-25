% Metodi del Calcolo Scientifico
% Progetto_1
% Mohammad Al� Manan (817205)
% Francesco Porto (816042)
% Stranieri Francesco (816551)

clear all
close all
clc

matrixFolder = 'SuiteSparse/MAT'; 
addpath(matrixFolder);
matrixList = dir(fullfile(matrixFolder, '*.mat'));

fileName = "result.txt";
formatOut = 'dd/mm/yy HH:MM:SS';

if ismac
        platform = "MacOS";
    elseif isunix
        platform = "Linux";
    elseif ispc
        platform = "Windows";
    else
        disp('Platform not supported')
        quit(1)
end

for i = 1:length(matrixList)
    load(matrixList(i).name);
    fileNameMatrix = split(matrixList(i).name,'.');
    matrixName = fileNameMatrix{1};
    fprintf('MatrixName %s \n',matrixName);

    matrixSize = size(Problem.A,1);
    fprintf('MatrixSize %d \n',matrixSize);
    nonZero = nnz(Problem.A);
    %spy(Problem.A)
    
    xEs = ones(matrixSize,1);
    b = Problem.A*xEs;
    
    logFileWrite = true;
    
    try
        profile clear
        profile -memory -history on
        tic;
    
        R = chol(Problem.A);
        x = R\(R'\b);

        executionTime = round(toc*1000);
        memoryAllocated = round((profile('info').FunctionTable().TotalMemAllocated)/1000);
        profile -memory -history off

        relativeError = norm(x- xEs)/norm(xEs);
    catch 
        executionTime = 0;
        memoryAllocated = 0;
        relativeError = 0;
        
        logFileWrite = false;
    end
    
    fprintf('ExecutionTime(ms) %d \n',executionTime);
    fprintf('MemoryAllocated(KB) %d \n',memoryAllocated);        
    fprintf('relativeError %e \n',relativeError);

    % logFile   
    if logFileWrite
        date = datestr(now,formatOut);
        logFile = fopen(fileName,'a');

        fprintf(logFile,'%s %s \n', 'DateTime:',date);
        fprintf(logFile,'%s %s \n', 'Platform:',platform);
        fprintf(logFile,'%s %s \n', 'Language:','MATLAB');
        fprintf(logFile,'%s %s \n', 'MatrixName:',matrixName);
        fprintf(logFile,'%s %d %s %d \n', 'MatrixSize:',matrixSize,'x',matrixSize);
        fprintf(logFile,'%s %d \n', 'NonZero:',nonZero);
        fprintf(logFile,'%s %e \n','RelativeError:',relativeError);
        fprintf(logFile,'%s %d \n','ExecutionTime(ms):',executionTime);
        fprintf(logFile,'%s %d \n','MemoryAllocated(KB):',memoryAllocated);
        fprintf(logFile,'%s \n', '');
        fclose(logFile);
    end
    
    clearvars ans b date executionTime fileNameMatrix logFile logFileWrite matrixName matrixSize memoryAllocated nonZero Problem R relativeError x xEs;
end
