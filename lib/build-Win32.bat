if "%1"=="" (
    echo lib      clean and build lib
    echo rcvv     build rcvv
    echo clean    clean all
    exit /b
)

set OUTBASE_PATH=%CD%\build\Win32
set OPENSSL=openssl-OpenSSL_1_1_1w
set N2N=n2n-3.1.1
set CMAKEBUILD_DIR=cmakebuild
set BUILD_DEBUG_DIR=_debug
set BUILD_RELEASE_DIR=_release
set BUDEBUG=/MTd
echo %OUTBASE_PATH%

if "%1"=="lib" (
    call C:\"Program Files"\"Microsoft Visual Studio"\2022\Community\VC\Auxiliary\Build\vcvarsamd64_x86.bat
    call :Build_clean
    call :Buildlib_debug
    call :Buildlib_release
    exit /b
) else if "%1"=="all" (
    call C:\"Program Files"\"Microsoft Visual Studio"\2022\Community\VC\Auxiliary\Build\vcvarsamd64_x86.bat
    call :Build_clean
    call :Buildlib_debug
    call :Buildlib_release
    exit /b
) else (
    call :Build_clean
    exit /b
)

:Build_clean
    rd /s /q  %OUTBASE_PATH%%BUILD_DEBUG_DIR%
    rd /s /q  %OUTBASE_PATH%%BUILD_RELEASE_DIR%
    rd /s /q  %OPENSSL%
    rd /s /q  %N2N%
exit /b

:Buildlib_release
    set BUILD_PATH=%OUTBASE_PATH%%BUILD_RELEASE_DIR%
    set BUILDMODE=Release
    set MSVC_RIMTIME=MultiThreaded
    set BUDEBUG=/MT
    call :Build_alllib
exit /b

:Buildlib_debug
    set BUILD_PATH=%OUTBASE_PATH%%BUILD_DEBUG_DIR%
    set BUILDMODE=Debug
    set MSVC_RIMTIME=MultiThreadedDebug
    set BUDEBUG=/MTd
    call :Build_alllib
exit /b

:Build_alllib
    call :Build_create
    call :Build_n2n
exit /b

:Build_create
    rd /s /q  %BUILD_PATH%

    if not exist %BUILD_PATH% (
        mkdir "%BUILD_PATH%"
    )

    if not exist %BUILD_PATH%/include (
        mkdir "%BUILD_PATH%"/include
    )

    if not exist %BUILD_PATH%/lib (
        mkdir "%BUILD_PATH%"/lib
    )

    if not exist %BUILD_PATH%/bin (
        mkdir "%BUILD_PATH%"/bin
    )
exit /b

:Build_n2n
    rd /s /q   %N2N%
    tar xvf %N2N%.tgz
    cd %N2N%
        rmdir /s/q %CMAKEBUILD_DIR%
        mkdir %CMAKEBUILD_DIR%
        cd %CMAKEBUILD_DIR%
        cmake .. -A win32 -G "Visual Studio 17 2022"        ^
                -DCMAKE_MSVC_RUNTIME_LIBRARY=%MSVC_RIMTIME% ^
                -DCMAKE_INSTALL_PREFIX=%BUILD_PATH%         ^
                        || ( echo run cmake  fail & exit /b)
        cmake --build   . --config %BUILDMODE%   || ( echo run cmakebuild    fail & exit )
        cmake --install . --config %BUILDMODE%   || ( echo run cmakeinstall  fail & exit )
    cd ..\..
exit /b