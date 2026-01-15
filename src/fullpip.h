//
// Created by patryk on 26.12.25.
//

#include "../src/dsp/SignalProcessing.h"

#ifndef FULLPIP_H

class FullPip
{
    public:
        FullPip(int winSize, int overlap, std::vector<float> coff_filter, dsp::WinType winType = dsp::WinType::Hann);

        std::vector<float> processCPU(std::vector<float> input);
        float* processGPU(std::vector<float> input, bool return_gpu = true);

    private:
        int winSize;
        int overlap;
        std::vector<float> coff_filter;
        dsp::WinType winType;

        int N; // liczba okien
};

#define FULLPIP_H

#endif //FULLPIP_H
