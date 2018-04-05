
#ifndef SORT_IPS_H
#define SORT_IPS_H

//------------------------------------------------------------------------------

#include "util.h"
#include "valid_ipv4.h"

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

// TODO - Make it so we do not have
// to truncate. Run this separately to
// see the results
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


#endif
