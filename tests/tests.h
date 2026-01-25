//
// Created by patryk on 25.12.25.
//

#include "../src/dsp/SignalProcessing.h"
#include "../src/structures/Signal.h"
#include "../src/utils/utils.h"
#include "iostream"

#include <cuda_runtime.h>

#ifndef TESTS_H
#define TESTS_H

bool test_firfilter();
bool test_win_applyer();
bool test_stft();
bool test_minmax();
bool test_resize();


#endif //TESTS_H
