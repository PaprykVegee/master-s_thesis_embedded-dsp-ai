#include <iostream>
#include <vector>
#include <chrono>
#include "src/fullpip.h"
#include "src/utils/utils.h"
#include "src/structures/Signal.h"
#include <fstream>

#include <NvInfer.h>

class Logger : public nvinfer1::ILogger {
public:
    void log(Severity severity, const char* msg) noexcept override {
        if (severity <= Severity::kWARNING)
            std::cout << msg << std::endl;
    }
} logger;

std::vector<char> loadEngine(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    f.seekg(0, std::ios::end);
    size_t size = f.tellg();
    f.seekg(0, std::ios::beg);
    std::vector<char> data(size);
    f.read(data.data(), size);
    return data;
}

int main(int argc, char* argv[]) {
	
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <path_to_input_file>" << std::endl;
        return 1;
    }

    std::string input_file = argv[1];

    cudaWarmup();
	cudaWarmup();
	cudaWarmup();

    // Wczytanie sygnału
    Signal signal(input_file);
    std::vector<float> originalSignal = signal.getSignal();
    std::cout << "debug" << std::endl;

    // FIR coefficients
	std::vector<float> fir_coeff = {
		-6.22306784141e-19, -0.000249723820228, -0.000121886379326, 0.000464301744213, 0.00115329587664, 0.00137619729156, 0.000826175708606, -0.00018539928305, -0.000887119191123, -0.000724385588735, 1.16209280889e-18, 0.000232259287887, -0.000856223045941, -0.00282889457298, -0.00401109670854, -0.0028761033194, 0.000327463122424, 0.00339402216342, 0.00398356005532, 0.00198159278452, 1.37722713301e-18, 0.00106044261687, 0.00530260604237, 0.00901769219938, 0.00756980795757, -9.24125574449e-18, -0.00912747450726, -0.0131166015332, -0.00931248743632, -0.00225166139203, -2.36136063588e-18, -0.00618723209277, -0.0151427955119, -0.0157596478541, -0.00186454117781, 0.0201706776504, 0.0348237871258, 0.0305769843119, 0.0115956550036, -0.00396918020027, 3.15754136444e-18, 0.0202076854621, 0.032084810013, 0.00879807319235, -0.0522062713656, -0.118100180901, -0.138390565063, -0.0818487506754, 0.034853027968, 0.151102544576, 0.199550844241, 0.151102544576, 0.034853027968, -0.0818487506754, -0.138390565063, -0.118100180901, -0.0522062713656, 0.00879807319235, 0.032084810013, 0.0202076854621, 3.15754136444e-18, -0.00396918020027, 0.0115956550036, 0.0305769843119, 0.0348237871258, 0.0201706776504, -0.00186454117781, -0.0157596478541, -0.0151427955119, -0.00618723209277, -2.36136063588e-18, -0.00225166139203, -0.00931248743632, -0.0131166015332, -0.00912747450726, -9.24125574449e-18, 0.00756980795757, 0.00901769219938, 0.00530260604237, 0.00106044261687, 1.37722713301e-18, 0.00198159278452, 0.00398356005532, 0.00339402216342, 0.000327463122424, -0.0028761033194, -0.00401109670854, -0.00282889457298, -0.000856223045941, 0.000232259287887, 1.16209280889e-18, -0.000724385588735, -0.000887119191123, -0.00018539928305, 0.000826175708606, 0.00137619729156, 0.00115329587664, 0.000464301744213, -0.000121886379326, -0.000249723820228, -6.22306784141e-19

	};
    // Inicjalizacja FullPip
    FullPip full_pip(256, 128, fir_coeff);

    // =======================
    // CPU TIMER
    // =======================
    auto start_cpu = std::chrono::high_resolution_clock::now();
    std::vector<float> stft_cpu = full_pip.processCPU(originalSignal);
    std::cout << "debug" << std::endl;
    auto end_cpu = std::chrono::high_resolution_clock::now();
    double cpu_time = std::chrono::duration<double, std::milli>(end_cpu - start_cpu).count();

    // =======================
    // GPU TIMER
    // =======================
	auto start_gpu = std::chrono::high_resolution_clock::now();
	float* stft_gpu = full_pip.processGPU(originalSignal, false);
	std::cout << "debug" << std::endl;
	auto end_gpu = std::chrono::high_resolution_clock::now();
	double gpu_time = std::chrono::duration<double, std::milli>(end_gpu - start_gpu).count();
    
    /*
    for (int i = 0; i < 10; i++) {
		auto start_gpu = std::chrono::high_resolution_clock::now();
		float* stft_gpu = full_pip.processGPU(originalSignal, false);
		std::cout << "debug" << std::endl;
		auto end_gpu = std::chrono::high_resolution_clock::now();
		double gpu_time = std::chrono::duration<double, std::milli>(end_gpu - start_gpu).count();
		
		auto start_cpu = std::chrono::high_resolution_clock::now();
		std::vector<float> stft_cpu = full_pip.processCPU(originalSignal);
		std::cout << "debug" << std::endl;
		auto end_cpu = std::chrono::high_resolution_clock::now();
		double cpu_time = std::chrono::duration<double, std::milli>(end_cpu - start_cpu).count();

		
		std::cout << "GPU processing time: " << gpu_time << " ms" << std::endl;
		std::cout << "CPU processing time: " << cpu_time << " ms" << std::endl;
	};
	*/


     std::vector<float> stft_gpu_vec(stft_gpu, stft_gpu + stft_cpu.size());

    // Zapis wyników
    signal.setSignal(stft_cpu);
    signal.writeSignal("../data/spectrogram_cpu.txt");

    signal.setSignal(stft_gpu_vec);
    signal.writeSignal("../data/spectrogram_gpu.txt");

    // =======================
    // PRINT TIMES
    // =======================
    std::cout << "CPU processing time: " << cpu_time << " ms" << std::endl;
    std::cout << "GPU processing time: " << gpu_time << " ms" << std::endl;
    
    /////////////////////////////////////////// test trt //////////////////////////////////////////////////////////////
    

try {
    auto engineData = loadEngine("../nn_model/resnet18_fp16.trt");

    nvinfer1::IRuntime* runtime = nvinfer1::createInferRuntime(logger);
    nvinfer1::ICudaEngine* engine = runtime->deserializeCudaEngine(engineData.data(), engineData.size());

    std::cout << "TRT engine loaded successfully ✅" << std::endl;

    // Wypisanie informacji o inputach
    for (int i = 0; i < engine->getNbBindings(); ++i) {
        if (engine->bindingIsInput(i)) {
            auto dims = engine->getBindingDimensions(i);
            std::cout << "Input " << i << " (" << engine->getBindingName(i) << ") shape: ";
            for (int d = 0; d < dims.nbDims; ++d) {
                if (dims.d[d] == -1)
                    std::cout << "dynamic ";
                else
                    std::cout << dims.d[d] << " ";
            }
            std::cout << std::endl;
        }
    }

    engine->destroy();
    runtime->destroy();

} catch (const std::exception& e) {
    std::cout << "Exception while testing TRT: " << e.what() << std::endl;
}


    return 0;
}


