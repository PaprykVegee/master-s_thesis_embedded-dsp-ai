//
// Created by patryk on 25.12.25.
//

#include "Signal.h"
#include <iostream>
#include <string>
#include <fstream>

Signal::Signal(const std::string path)
{
    readSignal(path);
}

void Signal::readSignal(const std::string& path) {
    std::ifstream ifs(path);
    if (!ifs.is_open()) {
        std::cerr << "Nie można otworzyć pliku!\n";
        return;
    }
    std::string line;
    while (std::getline(ifs, line)) {
        try {
            double value = std::stod(line);
            signal.push_back(value);
        } catch (const std::invalid_argument&) {
            signal.push_back(0);
        } catch (const std::out_of_range&) {
            signal.push_back(0);
        }
    }
}

void Signal::writeSignal(std::string path)
{
    std::ofstream ofs(path);
    if (!ofs.is_open()) {
        std::cerr << "Nie można otworzyć pliku!\n";
        return;
    }

    for (size_t i = 0; i < signal.size(); i++) {
        ofs << signal[i] << "\n";
    }
    ofs.close();
}

////////////////////////////////////////////////// Setery ////////////////////////////////////////////////////////
void Signal::setSignal(std::vector<float> signal) {
    this->signal = signal;
}

////////////////////////////////////////////////// Getery/////////////////////////////////////////////////////////
std::vector<float> Signal::getSignal()
{
    return signal;
}

float* Signal::getSignalPtr() {
    return signal.data();
}

const float* Signal::getConstSignalPtr()
{
    return signal.data();
}

const void Signal::printSignal()
{
    for (auto& val: signal)
        std::cout << val << std::endl;
}
