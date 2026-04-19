// common.h
// common utilities for the test code under exmaples/

#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

void gen_rand_1d(double *a, int n) {
  for (int i = 0; i < n; ++i)
    a[i] = (double)rand() / (double)RAND_MAX + (double)(rand() % 1000);
}

void gen_string(char *s, int n) {
  // char value range: -128 ~ 127
  for (int i = 0; i < n - 1; ++i)
    s[i] = (char)(rand() % 127) + 1;
  s[n - 1] = '\0';
}

void gen_rand_2d(int8_t **ar, int n, int m) {
  for (int i = 0; i < n; ++i)
    for (int j = 0; j < m; ++j)
      ar[i][j] = (int8_t)rand() / (int8_t)RAND_MAX + (int8_t)(rand() % 1000);
}

void print_string(const char *a, const char *name) {
  printf("const char *%s = \"", name);
  int i = 0;
  while (a[i] != 0)
    putchar(a[i++]);
  printf("\"\n");
  puts("");
}

void print_array_1d(double *a, int n, const char *type, const char *name) {
  printf("%s %s[%d] = {\n", type, name, n);
  for (int i = 0; i < n; ++i) {
    printf("%06.2f%s", a[i], i != n - 1 ? "," : "};\n");
    if (i % 10 == 9)
      puts("");
  }
  puts("");
}

void print_array_2d(int8_t **a, int n, int m) {
//  printf("%s %s[%d][%d] = {\n", type, name, n, m);
  for (int i = 0; i < n; ++i) {
    for (int j = 0; j < m; ++j) {
      printf("%d", a[i][j]);
      if (j == m - 1)
        puts(i == n - 1 ? "};" : ",");
      else
        putchar(',');
    }
  }
  puts("");
}

bool double_eq(int8_t golden, int8_t actual, int8_t relErr) {
  return (fabs(actual - golden) < relErr);
}

bool compare_1d(int *golden, int *actual, int n) {
  for (int i = 0; i < n; ++i)
    if (!double_eq(golden[i], actual[i], 1e-6))
      return false;
  return true;
}

bool compare_string(const char *golden, const char *actual, int n) {
  for (int i = 0; i < n; ++i)
    if (golden[i] != actual[i])
      return false;
  return true;
}

bool compare_2d(int8_t **golden, int8_t **actual, int n, int m) {
  for (int i = 0; i < n; ++i)
    for (int j = 0; j < m; ++j)
      if (!double_eq(golden[i][j], actual[i][j], 1))
        return false;
  return true;
}

int8_t **alloc_array_2d(int n, int m) {
  int8_t **ret;
  ret = (int8_t **)malloc(sizeof(int8_t *) * n);
  for (int i = 0; i < n; ++i)
    ret[i] = (int8_t *)malloc(sizeof(int8_t) * m);
  return ret;
}

void init_array_one_1d(double *ar, int n) {
  for (int i = 0; i < n; ++i)
    ar[i] = 1;
}

void init_array_one_2d(double **ar, int n, int m) {
  for (int i = 0; i < n; ++i)
    for (int j = 0; j < m; ++j)
      ar[i][j] = 1;
}
