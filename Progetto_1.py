# Metodi del Calcolo Scientifico
# Progetto_1 Python
# Mohammad Alì Manan (817205)
# Francesco Porto (816042)
# Stranieri Francesco (816551)

# https://docs.scipy.org/doc/scipy-0.14.0/reference/sparse.html
import scipy.io

# https://scikit-sparse.readthedocs.io/en/latest/cholmod.html
# https://readthedocs.org/projects/scikit-sparse/downloads/pdf/latest/
from sksparse.cholmod import cholesky

from numpy import ones, empty
from numpy.linalg import norm

import time
import os
import psutil

import pathlib
import platform as _platform
from datetime import datetime

import gc


def matrixSolver(matrix):
    fileNameMatrix = str(matrix).split(os.sep)[2]
    matrixName = fileNameMatrix.split(".")[0]
    print('MatrixName', matrixName)

    matrixProblem = scipy.io.loadmat(matrix)
    # print(sorted(matrixProblem.keys()))
    # print(matrixProblem['Problem'])

    # A = (matrixProblem['Problem'])['A'][0][0]

    matrixSize = ((matrixProblem['Problem'])['A'][0][0]).shape[0]
    print('MatrixSize', matrixSize)
    nnz = ((matrixProblem['Problem'])['A'][0][0]).getnnz()

    xEs = ones(matrixSize)
    b = ((matrixProblem['Problem'])['A'][0][0])*xEs
    x = empty(matrixSize)

    logFileWrite = True

    try:
        start = time.process_time()
        startMemoryAllocated = psutil.virtual_memory().used

        R = cholesky((matrixProblem['Problem'])['A'][0][0])
        x = R(b)

        endMemoryAllocated = psutil.virtual_memory().used
        # print((endMemoryAllocated.rss - startMemoryAllocated.rss) / 1000)

        executionTime = str(round((time.process_time() - start) * 1000))
        memoryAllocated = str(
            round((endMemoryAllocated - startMemoryAllocated) / 1000))
        relativeError = str("{:.7g}".format(norm(x - xEs) / norm(xEs)))
    except:
        executionTime = '0'
        memoryAllocated = '0'
        relativeError = '0'

        logFileWrite = False

    return (matrixName, matrixSize, nnz,
            executionTime, memoryAllocated, relativeError, logFileWrite)


def main():
    matrixFolder = "SuiteSparse/MAT/"
    matrixList = list(pathlib.Path(matrixFolder).glob('*.mat'))

    fileName = "result.txt"
    formatOut = "%d-%m-%Y %H:%M:%S"

    platform = _platform.system()
    if platform == 'Darwin':
        platform = 'MacOS'

    for matrix in matrixList:
        (matrixName, matrixSize, nnz,
         executionTime, memoryAllocated, relativeError, logFileWrite) = matrixSolver(matrix)

        gc.collect()

        print('ExecutionTime(ms)', executionTime)
        print('MemoryAllocated(KB)', memoryAllocated)
        print('RelativeError', relativeError)
        print()

        # logFile
        if logFileWrite:
            date = datetime.now().strftime(formatOut)

            with open(fileName, "a") as logFile:
                logFile.write('Date: ' + date + "\n" +
                              'Platform: ' + platform + "\n" +
                              'Language: ' + 'Python' + "\n" +
                              'MatrixName: ' + matrixName + "\n" +
                              'MatrixSize: ' + str(matrixSize) +
                              " x " + str(matrixSize) + "\n" +
                              'NonZero: ' + str(nnz) + "\n" +
                              'RelativeError: ' + relativeError + "\n" +
                              'ExecutionTime(ms): ' + executionTime + "\n" +
                              'MemoryAllocated(KB): ' + memoryAllocated + "\n" +
                              "\n")


if __name__ == "__main__":
    main()
