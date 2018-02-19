#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "../include/valid_ipv4.h"
#include "../include/util.h"


// Validate the list
bool valid_ip_list(char* ips[], int len) {
  int i;
  bool tmp;
  bool valid = true;

  // Check each ip
  for (i = 1; i < len; i++) {

    // Break on first
    // invalid ip
    if (!validate_ip(ips[i])) {
      printf("%s\n", ips[i]);
      fprintf(stderr, "ERROR: Invalid list of ip addresses\n");
      valid = false;
      break;
    }

    // printf("%s\n", ips[i]);
  }

  return valid;
}

//------------------------------------------------------------------------------

/**
 * Remove all non-numeric
 * values from a string and
 * returns a pointer to new
 * string with only numbers
 */
char* remove_dots(char* ip_str) {
  int   i;
  int   j;
  int   len     = strlen(ip_str);
  char* new_str = (char*) malloc(len * sizeof(char));

  // Loop through old string
  for (i = 0; i < len; i++) {

    // Only move numeric
    // values to new str
    if (is_numeric(ip_str[i])) {
        new_str[j] = ip_str[i];
        j++;
    }
  }

  // Null terminate it
  new_str[j] = '\0';

  return new_str;
}

//------------------------------------------------------------------------------

/**
 * Converts array of ip
 * strings to array of
 * integers (without dots)
 */
int* to_int_arr(char* ip_char_arr[], int len) {
  int*  ip_int_arr = (int*) malloc(len * sizeof(int));
  int   i;
  int   ip;
  char* no_dots;

  for (i = 0; i < len; i++) {

    // Get the string without dots
    no_dots = remove_dots(ip_char_arr[i]);

    // Convert to int
    ip = atoi(no_dots);

    // Store in array
    ip_int_arr[i] = ip;
  }

  // Free back to OS
  free(no_dots);

  return ip_int_arr;
}

//------------------------------------------------------------------------------

/**
 * Extracts the first
 * arg from command line
 * arguments, and returns
 * only the ones we want to
 * operate on.
 */
char** get_args(int argc, char* argv[]) {

  // Allocate # of rows
  char** new_argv = malloc((argc - 1) * sizeof(char*));
  int i;
  int s;

  // Allocate individual rows
  for (i = 1; i < argc; i++) {
    s = sizeof(argv[i]);
    new_argv[i-1] = malloc(s * sizeof(char));
    new_argv[i-1] = argv[i];
  }

  return new_argv;
}

//------------------------------------------------------------------------------

/**
 * Print list of ips
 * as strings to console
 */
void display(char** strs, int len) {
  int i;
  for (i = 0; i < len; i++) {
    printf("%s\n", strs[i]);
  }
}

//------------------------------------------------------------------------------

/**
 * For index i and j, swap
 * i and jth value in both arrays
 * so they stay in sync.
 */
void swap(int* ips, char** strs, int i, int j) {
  int temp_int;
  char* temp_str;

  temp_int = ips[i];
  temp_str = strs[i];

  ips[i]  = ips[j];
  strs[i] = strs[j];

  ips[j]  = temp_int;
  strs[j] = temp_str;
}

//------------------------------------------------------------------------------

/**
 * Bubble sort array in place
 * TODO - Implement better sort,
 * but works for now
 */
void sort(int* ips, char** strs, int len) {
  int i;
  int j;

  // Bubble sort
  for (i = 0; i < len; i++) {
    for (j = 0; j < len -i -1; j++) {
      if (ips[j] > ips[j+1]) {

        // Swap both ips as ints
        // and as strings so they
        // stay in synch (poor man's)
        // associative array
        swap(ips, strs, j, j+1);
      }
    }
  }
}

//------------------------------------------------------------------------------

bool sort_ips(int argc, char* argv[]) {
  int len = argc-1;

  // Get only the command line
  // args we need (everything but first)
  char** strs = get_args(argc, argv);

  // Convert ip strings to integers
  int* ips = to_int_arr(strs, len);

  // Sort them
  sort(ips, strs, len);

  // Print them
  display(strs, len);

  // Free memory
  // back to OS
  free(ips);
  free(strs);

  return true;
}

//------------------------------------------------------------------------------

/**
 * Sorts a list of ip
 * addresses in ascending order
 */
int main(int argc, char* argv[]) {

  // Validate list of ips, if it's good, sort and print them
  return valid_ip_list(argv, argc) && sort_ips(argc, argv) ? 0 : 1;
}
