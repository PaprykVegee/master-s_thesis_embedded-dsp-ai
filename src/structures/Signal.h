//
// Created by patryk on 25.12.25.
//

#ifndef SIGNAL_H
#define SIGNAL_H

#include <vector>
#include <string.h>
#include <string>


class Signal {
public:
    Signal(std::string path);

    void writeSignal(std::string path);

    const void printSignal();

    float* getSignalPtr();
    const float* getConstSignalPtr();
    std::vector<float> getSignal();

    void setSignal(std::vector<float> signal);

private:
    void readSignal(const std::string& path);

    std::vector<float> signal;
};


#endif //SIGNAL_H
