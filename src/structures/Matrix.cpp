//
// Created by patryk on 25.12.25.
//

#include "Matrix.h"

#include <iostream>

Matrix::Matrix(size_t rows, size_t cols) {
    this->rows = rows;
    this->cols = cols;
}

size_t Matrix::getCols() {
    return cols;
}

size_t Matrix::getRows() {
    return rows;
}

float* Matrix::getDataPtr() {
    return data.data();
}

std::vector<float> Matrix::getData() {
    return data;
}

void Matrix::fillData(std::vector<float> data) {
    std::copy(data.begin(), data.end(), std::back_inserter(this->data));
}

void Matrix::printData() {
    for (int i = 0; i < data.size(); i++) {
        std::cout << data[i] << " ";
        if (i % cols == 0)
            std::cout << std::endl;
    }

    std::cout << std::endl;
}
