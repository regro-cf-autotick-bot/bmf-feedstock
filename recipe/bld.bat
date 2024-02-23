: Use Ninja Generator
SET CMAKE_GEN=Ninja
SET CMAKE_GENERATOR=Ninja
SET CMAKE_GENERATOR_PLATFORM=
SET CMAKE_GENERATOR_TOOLSET=
SET CMAKE_PLAT=

: Setup win_rootfs
RMDIR /S /Q win_rootfs\x64\usr\include\openssl
DEL /Q win_rootfs\x64\usr\include\dlfcn.h
SET INCLUDE=%INCLUDE%;%CD%\win_rootfs\x64\usr\include;

: Setup CUDA Architectures
IF "%CUDA_COMPILER_VERSION%" == "11.2" (
    GOTO CUDA_SET_ARCH_11_2
) ELSE IF "%CUDA_COMPILER_VERSION%" == "11.8" (
    GOTO CUDA_SET_ARCH_11_8
) ELSE IF "%CUDA_COMPILER_VERSION%" == "12.0" (
    GOTO CUDA_SET_ARCH_12_0
) ELSE (
    GOTO CUDA_SET_ARCH_ALL
)

:CUDA_SET_ARCH_11_2
SET CUDA_ARCHS_LIST=35-real;37-real;50-real;52-real;60-real;61-real;70-real;75-real;80-real;86
GOTO CUDA_SET_ARCH_END
:CUDA_SET_ARCH_11_8
SET CUDA_ARCHS_LIST=35-real;37-real;50-real;52-real;60-real;61-real;70-real;75-real;80-real;86-real;90
GOTO CUDA_SET_ARCH_END
:CUDA_SET_ARCH_12_0
SET CUDA_ARCHS_LIST=50-real;52-real;60-real;61-real;70-real;75-real;80-real;86-real;90
GOTO CUDA_SET_ARCH_END
:CUDA_SET_ARCH_ALL
SET CUDA_ARCHS_LIST=all
GOTO CUDA_SET_ARCH_END
:CUDA_SET_ARCH_END

: Build
SET CMAKE_ARGS=%CMAKE_ARGS% -DBMF_LOCAL_DEPENDENCIES=OFF -DPython_EXECUTABLE=%PYTHON% -DBMF_ENABLE_CUDA=%BMF_BUILD_ENABLE_CUDA% -DHMP_CUDA_ARCH_FLAGS=%CUDA_ARCHS_LIST%
"%PYTHON%" -m pip install -v .
if %ERRORLEVEL% neq 0 exit 1

CD %PREFIX%\Lib\site-packages\bmf

: Move tools into environment binary dir
RMDIR /S /Q cmd
DEL /Q bin\test_hmp.exe
DEL /Q bin\hmp_perf_main.exe
COPY bin\* %LIBRARY_BIN%
RMDIR /S /Q bin

: Move headers into environment include dir
XCOPY /E include %LIBRARY_INC%
RMDIR /S /Q include

: Move SDK module libraries into environment library dir
DEL /Q lib\*.exp
DEL /Q lib\_bmf.lib lib\_hmp.lib
COPY lib\*.dll %LIBRARY_BIN%
DEL /Q lib\*.dll
COPY lib\*.lib %LIBRARY_LIB%
DEL /Q lib\*.lib
MOVE BUILTIN_CONFIG.json %LIBRARY_PREFIX%

: Move modules into environment root dir
MOVE cpp_modules %LIBRARY_PREFIX%\cpp_modules
MOVE python_modules %LIBRARY_PREFIX%\python_modules
