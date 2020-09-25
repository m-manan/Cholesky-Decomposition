# Metodi del Calcolo Scientifico
# Progetto_1 R
# Mohammad Alì Manan (817205)
# Francesco Porto (816042)
# Stranieri Francesco (816551)

## Packages
list.of.packages <- c("R.matlab", "Matrix", "profmem")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages))
  install.packages(new.packages)

library(R.matlab)
library(Matrix)
library(profmem)

dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))


matrixSolver <- function(matrix){
  fileNameMatrix <- unlist(strsplit(matrix, "\\/"))[3]
  matrixName <- unlist(strsplit(fileNameMatrix, "\\."))[1]
  cat("MatrixName ", matrixName, "\n")
  
  # https://www.rdocumentation.org/packages/rmatio/versions/0.14.0/topics/read.mat
  matrixProblem <- readMat(matrix)
  
  i = 1
  while(i < dim(matrixProblem$Problem)[1] & !identical(typeof(matrixProblem$Problem[[i]]), "S4")){ 
    i = i+1
  }
  
  matrixSize <- dim(matrixProblem$Problem[[i]])[1]
  cat("MatrixSize ", matrixSize, "\n")
  
  nonZero <- nnzero(matrixProblem$Problem[[i]])
  
  xEs <- matrix(1, matrixSize)
  b <- matrixProblem$Problem[[i]] %*% xEs
  
  logFileWrite <- TRUE
  
  tryCatch(
    expr = {
    # https://www.rdocumentation.org/packages/Matrix/versions/1.2-18/topics/Cholesky
    profiler <- profmem({
      start <- Sys.time()
      
      R <- Cholesky(matrixProblem$Problem[[i]])
      x <- solve(R, b)
      
      executionTime <- difftime(Sys.time(), start, units = "secs") * 1000
      executionTime <- unlist(strsplit(as.character(as.integer(executionTime)), " "))
      # https://cran.r-project.org/web/packages/profmem/vignettes/profmem.html
      relativeError <- signif(as.numeric((norm(x - xEs)) / norm(xEs)), 7)
      })
    memoryAllocated <- as.integer(sum(profiler$bytes) / 1000)
    },
    error = function(e){ 
      executionTime <- '0'
      memoryAllocated <- '0'
      relativeError <- '0'
      
      logFileWrite <- FALSE
    }
  )
  
  # https://stackoverflow.com/questions/8936099/returning-multiple-objects-in-an-r-function
  return(c(matrixName, matrixSize, nonZero,
         executionTime, memoryAllocated, relativeError, logFileWrite))
}


main <- function(){
  matrixFolder <- "SuiteSparse/MAT"
  matrixList <- Sys.glob(file.path(matrixFolder, "*.mat"))
  
  fileName <- "result.txt"
  formatOut <- "%d-%m-%Y %X"
  
  platform <- Sys.info()["sysname"]
  if (platform == 'Darwin')
    platform <- 'MacOS'

  for (matrix in matrixList){
    result <- matrixSolver(matrix)
    
    matrixName <- result[1]
    matrixSize <- result[2]
    nonZero <- result[3]
    executionTime <- result[4]
    memoryAllocated <- result[5]
    relativeError <- result[6]
    logFileWrite <- result[7]
    
    cat('ExecutionTime(ms)', executionTime, "\n")
    cat('MemoryAllocated(KB)', memoryAllocated, "\n")
    cat('RelativeError', relativeError, "\n")
    cat("\n")
  
    # logFile
    if (identical(logFileWrite, "TRUE")){
      date <- format(Sys.time(), "%d-%m-%Y %H:%M:%S")
      logFile <- file(fileName, "a+")
      
      cat(paste0("DateTime: ", date, "\n",
          "Platform: ", platform, "\n",
          "Language: ", "R", "\n", 
          "MatrixName: ", matrixName, "\n",
          "MatrixSize: ", matrixSize, " x ", matrixSize, "\n",
          "NonZero: ", nonZero, "\n", 
          "RelativeError: ", relativeError, "\n",
          "ExecutionTime(ms): ", executionTime, "\n",
          "MemoryAllocated(KB): ", memoryAllocated, "\n", 
          "\n"), 
          file = logFile)
      close(logFile)
    }
    
    rm(date, executionTime, logFile, matrixName, matrixSize, memoryAllocated, nonZero, relativeError, result)
    gc()
  }
}
