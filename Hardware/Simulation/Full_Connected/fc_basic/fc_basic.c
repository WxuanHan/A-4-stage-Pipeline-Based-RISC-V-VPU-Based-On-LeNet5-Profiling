#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"
#include "common.h" 

void print_array_2d(int8_t **array, int rows, int cols);
void fc(int8_t **input, int16_t **weights, int32_t *output, int input_rows, int input_cols, int output_size) {
    // Initialize the output matrix
    for (int i = 0; i < output_size; ++i) {
        output[i] = 0;
    }

    // Perform full connected layer calculations
    int idx = 0;
    for (int i = 0; i < input_rows; ++i) {
        for (int j = 0; j < input_cols; ++j) {
            for (int k = 0; k < output_size; ++k) {
                output[k] += input[i][j] * weights[idx][k];
            }
            idx++;
        }
    }
}

int main() {
    const int input_rows = 4;
    const int input_cols = 4;
    const int output_size = 2;
    uint32_t seed = 0xdeadbeef;
    srand(seed);

    // Generate and print the input matrix
    int8_t **input = alloc_array_2d(input_rows, input_cols);
    gen_rand_2d(input, input_rows, input_cols); 
    print_array_2d(input, input_rows, input_cols);

    // Manually assign and initialize the weights matrix
    int16_t **weights = malloc(16 * sizeof(int16_t *));
    for (int i = 0; i < 16; ++i) {
        weights[i] = malloc(2 * sizeof(int16_t));
	    // The first column weight is set to 1
	    weights[i][0] = 1;
	    // The second column weights are set to alternate 1 and -1
	    weights[i][1] = (i % 2 == 0) ? 1 : -1;
}

    // Initialize the output matrix
    int32_t *output = (int32_t *)malloc(output_size * sizeof(int32_t));

    // Calling fully connected layer functions
    fc(input, weights, output, input_rows, input_cols, output_size);

    // Print the weight matrix
    printf("\nWeights Matrix:\n");
    for (int i = 0; i < 16; i++) {
        printf("%d\t%d\n", weights[i][0], weights[i][1]);
    }

    // Print output matrix
    printf("FC Output:\n");
    for (int i = 0; i < output_size; ++i) {
        printf("%d ", output[i]);
    }
    printf("\n");

    // Resource cleanup
    for (int i = 0; i < input_rows; i++) free(input[i]);
    free(input);
    for (int i = 0; i < input_rows * input_cols; i++) free(weights[i]);
    free(weights);
    free(output);

    return 0;
}

