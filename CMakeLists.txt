cmake_minimum_required(VERSION 3.22)
project(CUDA LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)

# ==========================
# Ścieżka do TensorRT
# ==========================
set(TENSORRT_DIR "/home/patryk/Desktop/TensorRT-10.13.3.9")

# Dodaj katalog z nagłówkami TensorRT
include_directories(${TENSORRT_DIR}/include)

# Dodaj katalog z bibliotekami TensorRT, żeby linker znalazł pliki .so
link_directories(${TENSORRT_DIR}/lib)

# ==========================
# Główny target CUDA
# ==========================
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

# Nagłówki głównego targetu
target_include_directories(CUDA PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

# Linkowanie bibliotek dla głównego targetu
target_link_libraries(CUDA PRIVATE
 #       nvinfer          # TensorRT core
 #       nvparsers        # Parsery TensorRT (ONNX itd.)
        cudart           # CUDA Runtime
        cufft            # CUDA FFT
)

# ==========================
# Target do testów
# ==========================
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
        tests/test_resize.cu
        src/utils/utils.cpp
        src/utils/utils.h
        src/utils/utils.cu
        src/fullpip.h
        src/fullpip.cpp
        src/fullpip.cu
)

# Nagłówki testów
target_include_directories(tests PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

# Linkowanie bibliotek testów
target_link_libraries(tests PRIVATE
  #      nvinfer
  #      nvparsers
        cudart
        cufft
)
