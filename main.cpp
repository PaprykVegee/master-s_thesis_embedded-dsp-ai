#include <iostream>
#include <vector>
#include <chrono>
#include "src/fullpip.h"
#include "src/utils/utils.h"
#include "src/structures/Signal.h"
#include <fstream>

#include <algorithm>

#define WINDOW_SIZE 256
#define OVERLAP 128

// #include <NvInfer.h>

// class Logger : public nvinfer1::ILogger {
// public:
//     void log(Severity severity, const char* msg) noexcept override {
//         if (severity <= Severity::kWARNING)
//             std::cout << msg << std::endl;
//     }
// } logger;

// std::vector<char> loadEngine(const std::string& path) {
//     std::ifstream f(path, std::ios::binary);
//     f.seekg(0, std::ios::end);
//     size_t size = f.tellg();
//     f.seekg(0, std::ios::beg);
//     std::vector<char> data(size);
//     f.read(data.data(), size);
//     return data;
// }

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <path_to_input_file>" << std::endl;
        return 1;
    }

    std::string input_file = argv[1];
    cudaWarmup();


    /////////////////////////////////////////////////////////////////
    ///Przygotowanie syganlu
    Signal signal(input_file);
    std::vector<float> signal0 = signal.getSignal();
    std::vector<float> signal1 = signal.getSignal();
    std::vector<float> signal2 = signal.getSignal();

    int winSize = WINDOW_SIZE;
    int hop = WINDOW_SIZE - OVERLAP;
    int n_bins = winSize / 2 + 1; // 129

    size_t raw_max = std::max({signal0.size(), signal1.size(), signal2.size()});

    int n_frames_per_sig = (raw_max - winSize + hop - 1) / hop + 1;

    size_t safe_len = (n_frames_per_sig - 1) * hop + winSize;

    auto pad_signal = [&](std::vector<float>& s, size_t target_len) {
        if (s.size() < target_len) {
            s.resize(target_len, 0.0f);
        } else {
            s.resize(target_len);
        }
    };

    pad_signal(signal0, safe_len);
    pad_signal(signal1, safe_len);
    pad_signal(signal2, safe_len);

    std::vector<float> batched_signal;
    batched_signal.reserve(3 * safe_len);
    batched_signal.insert(batched_signal.end(), signal0.begin(), signal0.end());
    batched_signal.insert(batched_signal.end(), signal1.begin(), signal1.end());
    batched_signal.insert(batched_signal.end(), signal2.begin(), signal2.end());


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////

    std::vector<float> fir_coeff;
    fir_coeff.assign({-6.223067841408601e-19, -0.00024972382022756543, -0.00012188637932595435, 0.0004643017442130137, 0.001153295876641124, 0.0013761972915588385, 0.0008261757086055515, -0.00018539928305017492, -0.0008871191911226816, -0.000724385588734672, 1.1620928088932437e-18, 0.0002322592878868555, -0.0008562230459407229, -0.0028288945729827023, -0.004011096708543996, -0.002876103319402701, 0.0003274631224237096, 0.0033940221634155133, 0.003983560055323493, 0.001981592784516565, 1.3772271330054413e-18, 0.0010604426168742366, 0.005302606042371399, 0.009017692199381887, 0.007569807957574562, -9.241255744491766e-18, -0.00912747450725741, -0.013116601533158294, -0.009312487436315955, -0.0022516613920318404, -2.36136063587945e-18, -0.0061872320927745675, -0.015142795511903723, -0.015759647854102412, -0.0018645411778098126, 0.02017067765035316, 0.034823787125780055, 0.030576984311928686, 0.011595655003557321, -0.003969180200271806, 3.157541364438269e-18, 0.02020768546209116, 0.03208481001303284, 0.008798073192351923, -0.05220627136561067, -0.11810018090078797, -0.13839056506289205, -0.08184875067543387, 0.03485302796803332, 0.1511025445756602, 0.19955084424108904, 0.1511025445756602, 0.03485302796803332, -0.08184875067543387, -0.13839056506289205, -0.11810018090078794, -0.052206271365610665, 0.00879807319235192, 0.03208481001303284, 0.020207685462091157, 3.1575413644382687e-18, -0.0039691802002718045, 0.011595655003557317, 0.030576984311928686, 0.03482378712578005, 0.02017067765035316, -0.001864541177809812, -0.01575964785410241, -0.015142795511903716, -0.006187232092774566, -2.3613606358794498e-18, -0.0022516613920318396, -0.009312487436315953, -0.013116601533158285, -0.009127474507257406, -9.241255744491765e-18, 0.007569807957574558, 0.009017692199381885, 0.005302606042371395, 0.0010604426168742361, 1.3772271330054413e-18, 0.0019815927845165636, 0.003983560055323493, 0.00339402216341551, 0.00032746312242370936, -0.002876103319402697, -0.004011096708543991, -0.0028288945729827023, -0.0008562230459407217, 0.00023225928788685537, 1.1620928088932421e-18, -0.0007243855887346715, -0.0008871191911226816, -0.00018539928305017457, 0.000826175708605551, 0.001376197291558837, 0.0011532958766411231, 0.0004643017442130137, -0.00012188637932595426, -0.00024972382022756543, -6.223067841408601e-19});

    FullPip full_pip(winSize, OVERLAP, fir_coeff);
    std::cout << "debug" << std::endl;
    auto start_cpu = std::chrono::high_resolution_clock::now();
    std::vector<float> stft_cpu = full_pip.processCPU(batched_signal);
    auto end_cpu = std::chrono::high_resolution_clock::now();
    std::cout << "debug" << std::endl;
    auto start_gpu = std::chrono::high_resolution_clock::now();
    float* stft_gpu_raw = full_pip.processGPU(batched_signal, false);
    auto end_gpu = std::chrono::high_resolution_clock::now();
    std::cout << "debug" << std::endl;
    size_t expected_total_elements = 3 * n_frames_per_sig * n_bins;

    if (stft_cpu.size() > expected_total_elements) {
        stft_cpu.resize(expected_total_elements);
    }

    std::vector<float> stft_gpu_vec(stft_gpu_raw, stft_gpu_raw + 256*256*3);
    delete[] stft_gpu_raw;

    signal.setSignal(stft_cpu);
    signal.writeSignal("../data/spectrogram_cpu.txt");
    signal.setSignal(stft_gpu_vec);
    signal.writeSignal("../data/spectrogram_gpu.txt");

    std::cout << stft_cpu.size() << std::endl;

    std::cout << "--- Batch Processing Stats ---" << std::endl;
    std::cout << "Frames per channel: " << n_frames_per_sig << std::endl;
    std::cout << "Total elements (3 channels): " << expected_total_elements << std::endl;
    std::cout << "CPU time: " << std::chrono::duration<double, std::milli>(end_cpu - start_cpu).count() << " ms" << std::endl;
    std::cout << "GPU time: " << std::chrono::duration<double, std::milli>(end_gpu - start_gpu).count() << " ms" << std::endl;
    std::cout << "Is divisible by 3*129? " << (expected_total_elements % (3 * 129) == 0 ? "YES" : "NO") << std::endl;
    /////////////////////////////////////////// test trt //////////////////////////////////////////////////////////////
    

// try {
//     auto engineData = loadEngine("../nn_model/resnet18_fp16.trt");

//     nvinfer1::IRuntime* runtime = nvinfer1::createInferRuntime(logger);
//     nvinfer1::ICudaEngine* engine = runtime->deserializeCudaEngine(engineData.data(), engineData.size());

//     std::cout << "TRT engine loaded successfully ✅" << std::endl;

//     // Wypisanie informacji o inputach
//     for (int i = 0; i < engine->getNbBindings(); ++i) {
//         if (engine->bindingIsInput(i)) {
//             auto dims = engine->getBindingDimensions(i);
//             std::cout << "Input " << i << " (" << engine->getBindingName(i) << ") shape: ";
//             for (int d = 0; d < dims.nbDims; ++d) {
//                 if (dims.d[d] == -1)
//                     std::cout << "dynamic ";
//                 else
//                     std::cout << dims.d[d] << " ";
//             }
//             std::cout << std::endl;
//         }
//     }

//     engine->destroy();
//     runtime->destroy();

// } catch (const std::exception& e) {
//     std::cout << "Exception while testing TRT: " << e.what() << std::endl;
// }


    return 0;
}


