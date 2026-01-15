//
// Created by patryk on 25.12.25.
//

#include <vector>

#ifndef MATRIX_H
#define MATRIX_H

class Matrix {
public:
    Matrix(size_t rows, size_t cols);

    size_t getRows();
    size_t getCols();

    void fillData(std::vector<float> data);

    float* getDataPtr();

    std::vector<float> getData();

    void printData();
private:
    size_t rows;
    size_t cols;
    std::vector<float> data;
};

#endif //MATRIX_H
