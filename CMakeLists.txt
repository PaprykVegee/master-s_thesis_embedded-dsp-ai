cmake_minimum_required(VERSION 3.22)
project(CUDA LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)

# Twój główny program
add_executable(CUDA
        main.cpp
        src/cuda_kernels/kernels.cu
        src/dsp/SignalProcessing.cu
        src/structures/Signal.cpp
        src/structures/Matrix.cpp
        src/dsp/SignalProcessing.cpp
        src/utils/utils.h
        src/utils/utils.cpp
        src/utils/utils.cu
        src/fullpip.h
        src/fullpip.cpp
        src/fullpip.cu
)

target_include_directories(CUDA PRIVATE ${CMAKE_SOURCE_DIR}/src)

target_link_libraries(CUDA
        PRIVATE
        /usr/local/cuda/lib64/libcudart.so
        /usr/local/cuda/lib64/libcufft.so
)

# Osobny target dla testów
add_executable(tests
        tests/test_firfilter.cpp
        src/cuda_kernels/kernels.cu
        src/dsp/SignalProcessing.cu
        src/structures/Signal.cpp
        src/structures/Matrix.cpp
        src/dsp/SignalProcessing.cpp
        tests/test_win_applyer.cu
        tests/main_test.cpp
        tests/tests.h
        tests/test_stft.cu
        tests/test_minmax.cu
        src/utils/utils.cpp
        src/utils/utils.h
        src/utils/utils.cu
        src/fullpip.h
        src/fullpip.cpp
        src/fullpip.cu
)

target_include_directories(tests PRIVATE ${CMAKE_SOURCE_DIR}/src)

target_link_libraries(tests
        PRIVATE
        /usr/local/cuda/lib64/libcudart.so
        /usr/local/cuda/lib64/libcufft.so
)
