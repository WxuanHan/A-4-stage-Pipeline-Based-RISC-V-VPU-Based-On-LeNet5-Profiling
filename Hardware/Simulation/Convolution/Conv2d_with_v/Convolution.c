#include "common.h"
#include <riscv_vector.h>
#include <stdio.h>


// 2D Convolution
// Input matrix A[4][4], Convolution Kernel K[2][2] --> Output matrix C[3][3]
void conv2d(int8_t **a, int8_t **c, int n, int m, int k_h, int k_w) {
    // Define the convolution kernel
    int8_t k[2][2] = {{1, 0}, {0, -1}};
    size_t vlmax = __riscv_vsetvlmax_e8m1();

    for (int i = 0; i <= n - k_h; ++i) {
        for (int j = 0; j <= m - k_w; ++j) {
            // Initialize the accumulator
            vint8m1_t vec_sum = __riscv_vmv_v_x_i8m1(0, vlmax);
            for (int ki = 0; ki < k_h; ++ki) {
                for (int kj = 0; kj < k_w; ++kj) {
                    // Calculate the shift position of vector loading based on ki and kj
                    int index = j + kj; // Calculating column shifts
                    if (index < m) { // Ensuring that the boundary is not exceeded
                        vint8m1_t vec_a = __riscv_vle8_v_i8m1(&a[i + ki][index], vlmax);
                        int8_t k_val = k[ki][kj];
                        vint8m1_t vec_k = __riscv_vmv_v_x_i8m1(k_val, vlmax);

                        // Execute multiplication of elements and accumulate to vec_sum
                        vec_sum = __riscv_vadd_vv_i8m1(vec_sum, __riscv_vmul_vv_i8m1(vec_a, vec_k, vlmax), vlmax);
                    }
                }
            }

            // Extract the summed result from the vector registers and store it in the output matrix
            int8_t sum = __riscv_vmv_x_s_i8m1_i8(vec_sum);
            c[i][j] = sum;
        }
    }
}
// Reference implementation of 2D convolution without vectorization
void conv2d_reference(int8_t **a, int8_t **c, int n, int m, int k_h, int k_w) {
    // Define the convolution kernel
    int8_t k[2][2] = {{1, 0}, {0, -1}};

    // For each element of the output matrix
    for (int i = 0; i <= n - k_h; ++i) {
        for (int j = 0; j <= m - k_w; ++j) {
            int sum = 0; // Initialize the accumulator
            // Traverse the kernel
            for (int ki = 0; ki < k_h; ++ki) {
                for (int kj = 0; kj < k_w; ++kj) {
                    // Convolution operation: elements are multiplied and then accumulated
                    sum += a[i + ki][j + kj] * k[ki][kj];
                }
            }
            // Assign the result of the calculation to the corresponding element of the output matrix
            c[i][j] = sum;
        }
    }
}

// Compare two matrices for equality
bool compare(int8_t **m1, int8_t **m2, int rows, int cols) {
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
    const int K_H = 2;
    const int K_W = 2;
    uint32_t seed = 0xdeadbeef;
    srand(seed);
    int8_t **kernel = alloc_array_2d(K_H, K_W);
    
    // Data generation
    int8_t **A = alloc_array_2d(N, M);
    gen_rand_2d(A, N, M);

    // Compute
    int8_t **C = alloc_array_2d(N-K_H+1, M-K_W+1);
    int8_t **C_reference = alloc_array_2d(N-K_H+1, M-K_W+1);
    conv2d(A, C, N, M, K_H, K_W);
    conv2d_reference(A, C_reference, N, M, K_H, K_W);


    // Compare two matrices
    if (compare(C_reference, C, N-K_H+1, M-K_W+1)) {
        printf("Verification SUCCESS: Vectorized and reference implementations match.\n");
    } else {
        printf("Verification FAILED: Vectorized and reference implementations do not match.\n");
    }

     print_array_2d(A, N, M);
     print_array_2d(C, N-K_H+1, M-K_W+1);
     
     return 0;
  
}

