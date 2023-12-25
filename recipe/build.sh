set -x

if [[ "${target_platform}" != "${build_platform}" ]]; then
    # PyBind11 will find python3.X which returns a different
    # value for the "EXT_SUFFIX" which is inconsistent with
    # cross compilation
    # https://github.com/conda-forge/cross-python-feedstock/issues/75
    Python_EXECUTABLE=${BUILD_PREFIX}/bin/python
else
    Python_EXECUTABLE=${PYTHON}
fi

# Exclude Jetson architectures for non-ARM platform, because we know they will never be utilized.
if [[ "$target_platform" == linux-aarch64 ]]; then
    CUDA_ARCHS_LIST=all
elif [[ "$target_platform" == linux-ppc64le ]]; then
    CUDA_ARCHS_LIST="60-real;70"
elif [[ "$CUDA_COMPILER_VERSION" == "11.2" ]]; then
    CUDA_ARCHS_LIST="35-real;37-real;50-real;52-real;60-real;61-real;70-real;75-real;80-real;86"
elif [[ "$CUDA_COMPILER_VERSION" == "11.8" ]]; then
    CUDA_ARCHS_LIST="35-real;37-real;50-real;52-real;60-real;61-real;70-real;75-real;80-real;86-real;90"
elif [[ "$CUDA_COMPILER_VERSION" == "12.0" ]]; then
    CUDA_ARCHS_LIST="50-real;52-real;60-real;61-real;70-real;75-real;80-real;86-real;90"
else
    CUDA_ARCHS_LIST=all
fi

export CMAKE_GENERATOR=Ninja
export CMAKE_ARGS="${CMAKE_ARGS} -DBMF_LOCAL_DEPENDENCIES=OFF -DBMF_ENABLE_CUDA=${BMF_BUILD_ENABLE_CUDA} -DPython_EXECUTABLE=${Python_EXECUTABLE} -DHMP_CUDA_ARCH_FLAGS=${CUDA_ARCHS_LIST}"
"$PYTHON" -m pip install -v .

cd $PREFIX/lib/python${PY_VER}/site-packages/bmf

# Move tools into environment binary dir
rm -r cmd
rm bin/test_hmp
rm bin/hmp_perf_main
mv -v bin/* $PREFIX/bin/
rm -r bin

# Move headers into environment include dir
mv -v include/* $PREFIX/include/
rm -r include

# Move SDK module libraries into environment library dir
mv -v lib/lib* $PREFIX/lib/
mv -v BUILTIN_CONFIG.json $PREFIX/

# Move modules into environment root dir
mv -v *_modules $PREFIX/

cd lib

if [[ "$target_platform" == osx-* ]]
then
    HMP_NAME=$(ls _hmp.*)
    BMF_NAME=$(ls _bmf.*)
    install_name_tool -change @loader_path/libhmp.dylib @rpath/libhmp.dylib $HMP_NAME
    install_name_tool -change @loader_path/libhmp.dylib @rpath/libhmp.dylib $BMF_NAME
    install_name_tool -change @loader_path/libengine.dylib @rpath/libengine.dylib $BMF_NAME
    install_name_tool -change @loader_path/libbmf_module_sdk.dylib @rpath/libbmf_module_sdk.dylib $BMF_NAME
else
    patchelf --add-rpath '$ORIGIN/.' _bmf*

    # Prefer cuda-compat than system libcuda.so.1, if present
    patchelf --add-rpath $PREFIX/cuda-compat _bmf*
    for i in $(ls $PREFIX/lib/libhmp*); do
        patchelf --add-rpath $PREFIX/cuda-compat $i
    done
    for i in $(ls $PREFIX/lib/libbuiltin_modules*); do
        patchelf --add-rpath $PREFIX/cuda-compat $i
    done
fi
