//
// Created by patryk on 25.12.25.
//

#include "tests.h"

bool test_firfilter() {

    std::vector<float> fir_coeff = {
        0.0020395046501305893, 0.0021361459782720717, 0.002365577569209405, 0.002731093451858461, 0.0032340860681839903,
        0.0038739865880887893, 0.004648234485304411, 0.00555227723719692, 0.0065796005309615236, 0.007721788867696089,
        0.008968615962520554, 0.010308163851541149, 0.01172696914328666, 0.013210194401314497, 0.014741822223705599,
        0.016304869201378337, 0.017881616597192698, 0.019453854297612448, 0.02100313435334998, 0.022511030249130433,
        0.023959397928685764, 0.02533063455148792, 0.0266079309736304, 0.02777551402663862, 0.028818874813691702,
        0.029724979450539285, 0.030482458945007087, 0.03108177523011269, 0.03151536073623671, 0.03177772930144902,
        0.03186555666917236, 0.03177772930144902, 0.03151536073623671, 0.03108177523011269, 0.030482458945007087,
        0.029724979450539285, 0.028818874813691702, 0.02777551402663863, 0.026607930973630404, 0.02533063455148792,
        0.023959397928685768, 0.022511030249130436, 0.02100313435334998, 0.019453854297612455, 0.017881616597192704,
        0.016304869201378337, 0.014741822223705606, 0.013210194401314506, 0.01172696914328666, 0.010308163851541152,
        0.008968615962520564, 0.007721788867696089, 0.006579600530961528, 0.0055522772371969275, 0.004648234485304411,
        0.003873986588088791, 0.0032340860681839916, 0.002731093451858461, 0.002365577569209405, 0.0021361459782720717,
        0.0020395046501305893
    };

    Signal signal("../data/sum_sin_signal.txt");
    std::vector<float> originalSignal = signal.getSignal();

    dsp::FirFilter fir(fir_coeff);

    std::vector<float> cpu_filtred_signal = fir.processCPU(originalSignal);
    signal.setSignal(cpu_filtred_signal);
    signal.writeSignal("../data/filterd_signal_cpu.txt");

    float* gpu_filtred_signal = fir.processGPU(originalSignal, false);
    std::vector<float> signalgpu(originalSignal.size());
    signalgpu.assign(gpu_filtred_signal, gpu_filtred_signal + originalSignal.size());
    signal.setSignal(signalgpu);
    signal.writeSignal("../data/filterd_signal_gpu.txt");

    bool ok = true;
    float eps = 1e-3;

    for (size_t i = 0; i < cpu_filtred_signal.size(); ++i) {
        if (std::fabs(cpu_filtred_signal[i] - gpu_filtred_signal[i]) > eps) {
            std::cout << "Mismatch at index " << i
                      << ": CPU=" << cpu_filtred_signal[i]
                      << ", GPU=" << gpu_filtred_signal[i] << "\n";
            ok = false;
        }
    }

    delete[] gpu_filtred_signal;

    if (ok) {
        std::cout << "TEST PASSED: GPU and CPU values match within tolerance " << eps << std::endl;
    } else {
        std::cout << "TEST FAILED: Some values differ beyond tolerance " << eps << std::endl;
    }
    return ok;
}
