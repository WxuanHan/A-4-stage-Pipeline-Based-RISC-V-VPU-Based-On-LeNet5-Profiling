#include "common.h"
#include <riscv_vector.h>
#include <stdio.h>
#include <stdlib.h>

// Full connected Layer
// Input matrix A[4][4], Weight matrix [16][2] --> Output matrix [1][2]
void fc(int8_t **a, int8_t *output, int n, int m) {
    // Initialize the weight matrix
    int8_t weights[16][2];
    for (int i = 0; i < 16; ++i) {
        weights[i][0] = 1;          // The first column is full of 1
        weights[i][1] = (i % 2) ? -1 : 1;  // Second column alternates between 1 and -1
    }

    size_t vlmax = __riscv_vsetvlmax_e8m1();
    for (int col = 0; col < 2; ++col) {
        vint8m1_t vec_sum = __riscv_vmv_v_x_i8m1(0, vlmax);
        for (int i = 0; i < n; ++i) {
            int chunks = m / vlmax; // Determine how many full chunks we have
            for (int chunk = 0; chunk <= chunks; ++chunk) {
                size_t vl = __riscv_vsetvl_e8m1(m - chunk * vlmax);
                for (int j = chunk * vlmax; j < (chunk + 1) * vlmax && j < m; ++j) {
                    vint8m1_t vec_a = __riscv_vle8_v_i8m1(&a[i][j], vl);
                    vint8m1_t vec_w = __riscv_vle8_v_i8m1(&weights[i * m + j][col], vl);

                    vec_sum = __riscv_vadd_vv_i8m1(vec_sum, __riscv_vmul_vv_i8m1(vec_a, vec_w, vl), vl);
                }
            }
        }
        output[col] = __riscv_vmv_x_s_i8m1_i8(vec_sum);
    }
}

// Reference implementation of a fully connected layer without vectorization
void fc_reference(int8_t **a, int8_t *output, int n, int m) {
    // Initialize the weight matrix, same as the vectorized section
    int8_t weights[16][2];
    for (int i = 0; i < 16; ++i) {
        weights[i][0] = 1; // The first column is full of 1
        weights[i][1] = (i % 2) ? -1 : 1; // Second column alternates between 1 and -1
    }

    // Initialize the output matrix to 0
    output[0] = 0;
    output[1] = 0;

    // For each column of the output matrix
    for (int col = 0; col < 2; ++col) {
        int sum = 0;
        // Calculate the output of the fully connected layer
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < m; ++j) {
                sum += a[i][j] * weights[i * m + j][col];
            }
        }
        output[col] = sum;
    }
}

// Compare two arrays for equality
bool compare(int8_t *arr1, int8_t *arr2, int len) {
    for (int i = 0; i < len; i++) {
        if (arr1[i] != arr2[i]) {
            return false;
        }
    }
    return true;
}


int main() {
    const int N = 4;
    const int M = 4;
    uint32_t seed = 0xdeadbeef;
    srand(seed);
    
    // Initialize the input matrix A
    int8_t **A = alloc_array_2d(N, M);
    gen_rand_2d(A, N, M);
    
    // Print input matrix A
    printf("Input Matrix A:\n");
    print_array_2d(A, N, M);
    
    // Computing fc using reference implementations
    int8_t output_reference[2] = {0};
    fc_reference(A, output_reference, N, M);

    // Initialize and compute FC layer outputs
    int8_t output[2] = {0};
    fc(A, output, N, M);

    // Print the weight matrix and output
    printf("Weight Matrix:\n");
    for (int i = 0; i < 16; i++) {
        printf("%4d %4d\n", 1, (i % 2) ? -1 : 1);
    }

    printf("Output Matrix:\n");
    printf("%4d %4d\n", output[0], output[1]);
    
    // Compare and print verification results
    if (compare(output, output_reference, 2)) {
        printf("Verification SUCCESS: Vectorized and reference implementations match.\n");
    } else {
        printf("Verification FAILED: Vectorized and reference implementations do not match.\n");
    }
    
    return 0;
}
