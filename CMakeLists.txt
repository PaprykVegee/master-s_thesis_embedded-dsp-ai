cmake_minimum_required(VERSION 3.10)

project(CUDA CXX)

# ========================
# Standard C++
# ========================
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ========================
# CUDA (stary styl)
# ========================
find_package(CUDA REQUIRED)

set(CUDA_STANDARD 14)
set(CUDA_STANDARD_REQUIRED ON)

# NVCC flags
set(CUDA_NVCC_FLAGS
        ${CUDA_NVCC_FLAGS}
        -std=c++14
        --expt-relaxed-constexpr
)

# ========================
# Ścieżki do TensorRT
# ========================
set(TENSORRT_INCLUDE_DIR /usr/include/aarch64-linux-gnu)
set(TENSORRT_LIB_DIR /usr/lib/aarch64-linux-gnu)

include_directories(${TENSORRT_INCLUDE_DIR})
link_directories(${TENSORRT_LIB_DIR})

# ========================
# Include directories
# ========================
include_directories(
        ${CUDA_INCLUDE_DIRS}
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_SOURCE_DIR}/src/ML_clf 
)

# ========================
# Ścieżka do libcudart
# ========================
link_directories(/usr/local/cuda-10.2/targets/aarch64-linux/lib)

# ========================
# Wspólne źródła
# ========================
set(COMMON_SOURCES
        src/cuda_kernels/kernels.cu
        src/dsp/SignalProcessing.cu
        src/dsp/SignalProcessing.cpp
        src/structures/Signal.cpp
        src/structures/Matrix.cpp
        src/utils/utils.cpp
        src/utils/utils.cu
        src/fullpip.cpp
        src/fullpip.cu
        src/ML_clf/trt_clf.cu
)

# ========================
# Główny program
# ========================
cuda_add_executable(CUDA
        main.cu
        ${COMMON_SOURCES}
)

target_link_libraries(CUDA
        ${CUDA_LIBRARIES}
        ${CUDA_CUFFT_LIBRARIES}
        nvinfer
        nvinfer_plugin
        cudart
        pthread
        dl
        z
)

# ========================
# TESTY
# ========================
cuda_add_executable(tests
        tests/main_test.cpp
        tests/test_firfilter.cpp
        tests/test_win_applyer.cu
        tests/test_stft.cu
        tests/test_minmax.cu
        tests/test_resize.cu
        ${COMMON_SOURCES}
)

target_link_libraries(tests
        ${CUDA_LIBRARIES}
        ${CUDA_CUFFT_LIBRARIES}
        nvinfer
        nvinfer_plugin
        cudart
        pthread
        dl
        z
)

