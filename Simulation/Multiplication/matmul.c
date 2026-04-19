#include "common.h"
#include <riscv_vector.h>

// matrix multiplication
// A[n][o], B[m][o] --> C[n][m];
void matmul_golden(int8_t **a, int8_t **b, int8_t **c, int n, int m, int o) {
  for (int i = 0; i < n; ++i)
    for (int j = 0; j < m; ++j) {
      c[i][j] = 0;
      for (int k = 0; k < o; ++k)
        c[i][j] += a[i][k] * b[j][k];
    }
}

void matmul(int8_t **a, int8_t **b, int8_t **c, int n, int m, int o) {
  size_t vlmax = __riscv_vsetvlmax_e8m1();
  for (int i = 0; i < n; ++i) {
    for (int j = 0; j < m; ++j) {
      int8_t *ptr_a = &a[i][0];
      int8_t *ptr_b = &b[j][0];
      int k = o;
      vint8m1_t vec_s = __riscv_vmv_v_x_i8m1(0, vlmax);
      vint8m1_t vec_zero = __riscv_vmv_v_x_i8m1(0, vlmax);
      for (size_t vl; k > 0; k -= vl, ptr_a += vl, ptr_b += vl) {
        vl = __riscv_vsetvl_e8m1(k);

        vint8m1_t vec_a = __riscv_vle8_v_i8m1(ptr_a, vl);
        vint8m1_t vec_b = __riscv_vle8_v_i8m1(ptr_b, vl);

        vec_s = __riscv_vmul_vv_i8m1(vec_a, vec_b, vl);
      }

      vint8m1_t vec_sum;
      vec_sum = __riscv_vredsum_vs_i8m1_i8m1(vec_s, vec_zero, vlmax);
      int8_t sum = __riscv_vmv_x_s_i8m1_i8(vec_sum);
      c[i][j] = sum;
    }
  }
}

int main() {
  const int N = 4;
  const int M = 4;
  const int O = 4;
  uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  int8_t **A = alloc_array_2d(N, O);
  int8_t **B = alloc_array_2d(M, O);
  gen_rand_2d(A, N, O);
  gen_rand_2d(B, M, O);

  // compute
  int8_t **golden = alloc_array_2d(N, M);
  int8_t **actual = alloc_array_2d(N, M);
  matmul_golden(A, B, golden, N, M, O);
  matmul(A, B, actual, N, M, O);

  // compare
  puts(compare_2d(golden, actual, N, M) ? "pass" : "fail");
//  print_array_2d(golden, N, M);
//  print_array_2d(actual, N, M);
}
