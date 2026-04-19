#include "common.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

// 2 Dimension Max Pooling
void maxpooling(int8_t **input, int8_t **output, int input_rows, int input_cols, int window_size, int stride) {
    int output_rows = (input_rows - window_size) / stride + 1;
    int output_cols = (input_cols - window_size) / stride + 1;

    for (int i = 0; i < output_rows; ++i) {
        for (int j = 0; j < output_cols; ++j) {
            int8_t max_val = INT8_MIN;
            for (int k = 0; k < window_size; ++k) {
                for (int l = 0; l < window_size; ++l) {
                    int8_t val = input[i * stride + k][j * stride + l];
                    if (val > max_val) {
                        max_val = val;
                    }
                }
            }
            output[i][j] = max_val;
        }
    }
}

int main() {
    const int N = 4;
    const int O = 4;
    uint32_t seed = 0xdeadbeef;
    srand(seed);

    // Allocate and generate random 2D array
    int8_t **A = alloc_array_2d(N, O);
    gen_rand_2d(A, N, O);
    printf("Input Array:\n");
    print_array_2d(A, N, O);

    // Prepare for max pooling
    const int window_size = 2; // Size of the pooling window
    const int stride = 2; // Stride for the pooling operation
    int output_rows = (N - window_size) / stride + 1;
    int output_cols = (O - window_size) / stride + 1;

    int8_t **pool_output = alloc_array_2d(output_rows, output_cols);

    // Perform max pooling
    maxpooling(A, pool_output, N, O, window_size, stride);
    printf("Max Pooling Output:\n");
    print_array_2d(pool_output, output_rows, output_cols);

    // Free allocated memory for A
    for (int i = 0; i < N; i++) {
        free(A[i]);
    }
    free(A);

    // Free allocated memory for pool_output
    for (int i = 0; i < output_rows; i++) {
        free(pool_output[i]);
    }
    free(pool_output);

    return 0;
}
