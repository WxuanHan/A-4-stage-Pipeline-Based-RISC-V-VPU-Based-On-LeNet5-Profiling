#include "common.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <riscv_vector.h>


// Maxpooling
// Input matrix A[4][4], Window size [2][2], Stride 2 --> Output matrix C[2][2]
void maxpooling(int8_t **a, int8_t **c, int n, int m, int window_size, int stride) {
    const size_t vlmax = __riscv_vsetvlmax_e8m1();
    const int output_rows = (n - window_size) / stride + 1;
    const int output_cols = (m - window_size) / stride + 1;

    for (int oi = 0; oi < output_rows; ++oi) {
        for (int oj = 0; oj < output_cols; ++oj) {
            int8_t max_val = INT8_MIN;
            for (int wi = 0; wi < window_size; wi += stride) {
                for (int wj = 0; wj < window_size; wj += stride) {
                    // Calculate effective width and height for possibly partial blocks at edges
                    int effective_width = (wi + vlmax < window_size) ? vlmax : window_size - wi;
                    int effective_height = (wj + vlmax < window_size) ? vlmax : window_size - wj;

                    for (int block_start_i = 0; block_start_i < effective_height; block_start_i++) {
                        for (int block_start_j = 0; block_start_j < effective_width; block_start_j += vlmax) {
                            // Compute vector length for the current block
                            size_t vl = __riscv_vsetvl_e8m1(effective_width - block_start_j);
                            vint8m1_t vec_block = __riscv_vle8_v_i8m1(&a[oi * stride + wi + block_start_i][oj * stride + wj + block_start_j], vl);
                            vint8m1_t vec_max = __riscv_vredmax_vs_i8m1_i8m1(vec_block, vec_block, vl);
                            int8_t block_max = __riscv_vmv_x_s_i8m1_i8(vec_max);
                            max_val = (block_max > max_val) ? block_max : max_val;
                        }
                    }
                }
            }
            c[oi][oj] = max_val;
        }
    }
}



// Reference implementation of maxpooling without vectorization
void maxpooling_reference(int8_t **a, int8_t **c, int n, int m, int window_size, int stride) {
    for (int i = 0; i <= n - window_size; i += stride) {
        for (int j = 0; j <= m - window_size; j += stride) {
            int8_t max_val = INT8_MIN; // Initialized to the smallest 8-bit integer

            for (int wi = 0; wi < window_size; ++wi) {
                for (int wj = 0; wj < window_size; ++wj) {
                    // Selects the maximum value in the current window
                    int8_t current_val = a[i + wi][j + wj];
                    if (current_val > max_val) {
                        max_val = current_val;
                    }
                }
            }

            // Stores the maximum value of the current window to the output matrix
            c[i/stride][j/stride] = max_val;
        }
    }
}

// Compare two matrices for equality
bool compare_matrices(int8_t **m1, int8_t **m2, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if (m1[i][j] != m2[i][j]) {
                return false;
            }
        }
    }
    return true;
}

int main() {
    const int N = 4;
    const int M = 4;
    const int window_size = 2;
    const int STRIDE = 2;
    uint32_t seed = 0xdeadbeef;
    srand(seed);

    int output_rows = (N - window_size) / STRIDE +1;
    int output_cols = (M - window_size) / STRIDE +1;
    
    // Allocate and generate random 2D array
    int8_t **A = alloc_array_2d(N, M);
    gen_rand_2d(A, N, M);

    // Allocate output array
    int8_t **C = alloc_array_2d(output_rows, output_cols);

    // Perform Maxpooling
    maxpooling(A, C, N, M, window_size, STRIDE);
    
    //Reference
    int8_t **C_reference = alloc_array_2d(output_rows, output_cols);
    maxpooling_reference(A, C_reference, N, M, window_size, STRIDE);


    // Print arrays
    printf("Input Matrix A:\n");
    print_array_2d(A, N, M);
    printf("Output Matrix C:\n");
    print_array_2d(C, output_rows, output_cols);
    
    // Compare and print verification results
    if (compare_matrices(C, C_reference, output_rows, output_cols)) {
        printf("Verification SUCCESS: Vectorized and reference implementations match.\n");
    } else {
        printf("Verification FAILED: Vectorized and reference implementations do not match.\n");
    }

    // Free allocated memory for A
    for (int i = 0; i < N; i++) {
        free(A[i]);
    }
    free(A);

    // Free allocated memory for pool_output
    for (int i = 0; i < output_rows; i++) {
        free(C[i]);
    }
    free(C);

    return 0;
}
