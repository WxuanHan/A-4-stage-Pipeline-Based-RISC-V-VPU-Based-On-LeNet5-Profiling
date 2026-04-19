#include "common.h"
#include <riscv_vector.h>
#include <stdlib.h>
#include <stdio.h>


bool compare_2d(int8_t **a, int8_t **b, int rows, int cols);
void print_array_2d(int8_t **array, int rows, int cols);

// 2 Dimension Convolution
void conv2d(int8_t **input, int8_t **kernel, int8_t **output, int input_rows, int input_cols, int kernel_rows, int kernel_cols) {
    int output_rows = input_rows - kernel_rows + 1;
    int output_cols = input_cols - kernel_cols + 1;

    for (int i = 0; i < output_rows; ++i) {
        for (int j = 0; j < output_cols; ++j) {
            output[i][j] = 0;
            for (int k = 0; k < kernel_rows; ++k) {
                for (int l = 0; l < kernel_cols; ++l) {
                    output[i][j] += input[i+k][j+l] * kernel[k][l];
                }
            }
        }
    }
}


int main() {
  const int N = 4;
  const int O = 4;
  uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  int8_t **A = alloc_array_2d(N, O);
  gen_rand_2d(A, N, O);
    //A[0][0] = 50; A[0][1] = 62; A[0][2] = -11; A[0][3] = 11;
    //A[1][0] = 10; A[1][1] = -60; A[1][2] = -21; A[1][3] = -8;
    //A[2][0] = 9; A[2][1] = 25; A[2][2] = -32; A[2][3] = 39;
    //A[3][0] = 46; A[3][1] = -38; A[3][2] = 56; A[3][3] = -30;
  print_array_2d(A, N, O);

// Initialization and data preparation section
const int kernel_size = 2; // Size of the convolution kernel
int8_t **kernel = alloc_array_2d(kernel_size, kernel_size);
int8_t **conv_output = alloc_array_2d(N - kernel_size + 1, O - kernel_size + 1);
int8_t **expected_output = alloc_array_2d(N - kernel_size + 1, O - kernel_size + 1);

// Initialization
for (int i = 0; i < N - kernel_size + 1; i++) {
    for (int j = 0; j < O - kernel_size + 1; j++) {
        expected_output[0][0] = 110; expected_output[0][1] = 83; expected_output[0][2] = -3;
	expected_output[1][0] = -15; expected_output[1][1] = -28; expected_output[1][2] = -60;
	expected_output[2][0] = 47; expected_output[2][1] = -31; expected_output[2][2] = -2; 
    }
}
        
  // Definition and memory allocation of convolution kernel
  int kernel_rows = 2;
  int kernel_cols = 2;

    //Set the random value of the convolution kernel
      //gen_rand_2d(kernel, kernel_rows, kernel_cols);
    // Set the value of the convolution kernel
    kernel[0][0] = 1; kernel[0][1] = 0;
    kernel[1][0] = 0; kernel[1][1] = -1;

    // Calling conv2d function for convolution operation
    conv2d(A, kernel, conv_output, N, O, kernel_rows, kernel_cols);
    printf("Actual Convolution Output:\n");
    print_array_2d(conv_output, N - kernel_size + 1, O - kernel_size + 1);
    // Validation of results
bool is_equal = true;
for (int i = 0; i < N - kernel_rows + 1; i++) {
    for (int j = 0; j < O - kernel_cols + 1; j++) {
        if (conv_output[i][j] != expected_output[i][j]) { // Assuming expected_output is the expected result
            is_equal = false;
            break;
        }
    }
    if (!is_equal) break;
}
printf("Convolution Operation Result%s\n", is_equal ? " is Right" : " is Wrong");

    // Resource clean-up
    for (int i = 0; i < N; i++) free(A[i]);
    free(A);
    for (int i = 0; i < N - kernel_rows + 1; i++) free(conv_output[i]);
    free(conv_output);
    for (int i = 0; i < kernel_rows; i++) free(kernel[i]);
    free(kernel);


  return 0;
}
