// Metodi del Calcolo Scientifico
// Progetto_1 C++
// Mohammad Alì Manan (817205)
// Francesco Porto (816042)
// Stranieri Francesco (816551)

#include <dirent.h>
#include <iostream>
#include <fstream>
#include <math.h>
#include <chrono>
#include <ctime>

#include "eigen-3.3.7/Eigen/Sparse"
#include "eigen-3.3.7/unsupported/Eigen/SparseExtra"

#if defined(_WIN32) || defined(__CYGWIN__)
#include <windows.h>
#include <psapi.h>
std::string platform("Windows");
#elif defined(__linux__) || defined(__linux) || defined(linux) || defined(__gnu_linux__)
#include <unistd.h>
#include <sys/resource.h>
std::string platform("Linux");
#elif defined(__APPLE__) && defined(__MACH__)
#include <mach/mach.h>
std::string platform("MacOS");
#else
#error Platform not supported!
#endif

// https://stackoverflow.com/questions/669438/how-to-get-memory-usage-at-runtime-using-c
/*
 * Author:  David Robert Nadeau
 * Site:    http://NadeauSoftware.com/
 * License: Creative Commons Attribution 3.0 Unported License
 *          http://creativecommons.org/licenses/by/3.0/deed.en_US
 */
size_t getCurrentRSS();

struct matrixSolved
{
        int matrixSize;
        int nnz;
        int memoryAllocated;
        int executionTime;
        double relativeError;
        bool logFileWrite;
};

matrixSolved matrixSolver(const char *matrixList);

using namespace Eigen;
using namespace std;
using namespace std::chrono;

typedef SparseMatrix<double> SpMat;

int main()
{
        DIR *matrixFolder;
        char *matrixName, *matrixExtension;
        struct dirent *dir;

        const char *matrixPath = "SuiteSparse/MTX/";
        matrixFolder = opendir(matrixPath);

        if (!matrixFolder)
        {
                cout << "Fatal Error! Folder NOT Found." << endl;
                return -1;
        }

        while ((dir = readdir(matrixFolder)) != NULL)
        {
                matrixName = strtok(dir->d_name, ".");
                matrixExtension = strtok(NULL, ".");

                if (matrixExtension == NULL || strcmp(matrixExtension, "mtx") != 0)
                        continue;

                int matrixListLength = sizeof(matrixPath) + sizeof(matrixName) + sizeof(matrixExtension) + 2;
                char matrixList[matrixListLength];

                strcpy(matrixList, matrixPath);
                strcat(matrixList, matrixName);
                strcat(matrixList, ".");
                strcat(matrixList, matrixExtension);

                cout << "MatrixName " << matrixName << endl;
                matrixSolved matrixSolved = matrixSolver(matrixList);

                cout << "ExecutionTime(ms) " << matrixSolved.executionTime << endl;
                cout << "MemoryAllocated(KB) " << matrixSolved.memoryAllocated << endl;
                cout << "RelativeError " << matrixSolved.relativeError << endl;

                // logFile
                if(matrixSolved.logFileWrite){
                        time_t now = system_clock::to_time_t(system_clock::now());
                        char date[20];
                        strftime(date, sizeof(date), "%d-%m-%Y %H:%M:%S", localtime(&now));

                        ofstream logFile;
                        logFile.open("result.txt", ios_base::app);
                        logFile << "Date: " << date << "\n";
                        logFile << "Platform: " << platform << "\n";
                        logFile << "Language: "
                                << "C++"
                                << "\n";
                        logFile << "MatrixName: " << matrixName << "\n";
                        logFile << "MatrixSize: " << matrixSolved.matrixSize << " x " << matrixSolved.matrixSize << "\n";
                        logFile << "NonZero: " << matrixSolved.nnz << "\n";
                        logFile << "RelativeError: " << matrixSolved.relativeError << "\n";
                        logFile << "ExecutionTime(ms): " << matrixSolved.executionTime << "\n";
                        logFile << "MemoryAllocated(KB): " << matrixSolved.memoryAllocated << "\n";
                        logFile
                        << "\n";
                        logFile.close();
                }
        }
        closedir(matrixFolder);
}

size_t getCurrentRSS()
{
#if defined(_WIN32) || defined(__CYGWIN__)
        PROCESS_MEMORY_COUNTERS info;
        GetProcessMemoryInfo(GetCurrentProcess(), &info, sizeof(info));
        return (size_t)info.WorkingSetSize;
#elif defined(__linux__) || defined(__linux) || defined(linux) || defined(__gnu_linux__)
        long rss = 0L;
        FILE *fp = NULL;
        if ((fp = fopen("/proc/self/statm", "r")) == NULL)
                return (size_t)0L; /* Can't open? */
        if (fscanf(fp, "%*s%ld", &rss) != 1)
        {
                fclose(fp);
                return (size_t)0L; /* Can't read? */
        }
        fclose(fp);
        return (size_t)rss * (size_t)sysconf(_SC_PAGESIZE);
#elif defined(__APPLE__) && defined(__MACH__)
        struct mach_task_basic_info info;
        mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
        if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO,
                      (task_info_t)&info, &infoCount) != KERN_SUCCESS)
                return (size_t)0L; /* Can't access? */
        return (size_t)info.resident_size;
#else
#error Platform not supported!
        return (size_t)0L; /* Unsupported. */
#endif
}

matrixSolved matrixSolver(const char *matrixList)
{
        matrixSolved matrixSolved;

        // https://eigen.tuxfamily.org/dox/group__TutorialSparse.html
        SpMat A;
        loadMarket(A, matrixList);

        matrixSolved.matrixSize = A.rows();
        cout << "MatrixSize " << matrixSolved.matrixSize << endl;
        matrixSolved.nnz = A.nonZeros();

        VectorXd xEs = VectorXd::Ones(matrixSolved.matrixSize);
        VectorXd b = A * xEs;
        VectorXd x = VectorXd::Zero(matrixSolved.matrixSize);
        
        matrixSolved.logFileWrite = true;

        try
        {
                size_t memoryAllocatedStart = getCurrentRSS();
                high_resolution_clock::time_point start = high_resolution_clock::now();

                SimplicialLLT<SpMat> solver(A);
                x = solver.solve(b);

                high_resolution_clock::time_point stop = high_resolution_clock::now();
                duration<double, milli> differenceTime = (stop - start);
                size_t memoryAllocatedEnd = getCurrentRSS();

                matrixSolved.memoryAllocated = (memoryAllocatedEnd - memoryAllocatedStart) / 1000;
                matrixSolved.executionTime = round(differenceTime.count());
                matrixSolved.relativeError = (x - xEs).norm() / xEs.norm();
        }
        catch (...)
        {
                matrixSolved.memoryAllocated = 0;
                matrixSolved.executionTime = 0;
                matrixSolved.relativeError = 0;
                
                matrixSolved.logFileWrite = false;
        }

        return matrixSolved;
}
