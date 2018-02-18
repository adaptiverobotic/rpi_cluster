#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>

// Declare booleans
// because C doesn't
// have them
typedef int bool;
#define true 1
#define false 0

// Struct that represents the lower
// and upper bounds of a
// gieven IPv4 address class
typedef struct octet_bound octet_bound;
struct octet_bound {
  int upper[4];
  int lower[4];
};

// Bounds for class A addresses
static octet_bound class_A = {
  .lower = {1, 0, 0, 1},
  .upper = {126, 255, 255, 254}
};

// Bounds for class B addresses
static octet_bound class_B = {
  .lower = {128, 1, 0, 1},
  .upper = {191, 255, 255, 254}
};

// Bounds for class C addresses
static octet_bound class_C = {
  .lower = {192, 0, 1, 1},
  .upper = {223, 255, 254, 254}
};

// Bounds for class D addresses
static octet_bound class_D = {
  .lower = {224, 0, 0, 0},
  .upper = {239, 255, 255, 255}
};

//------------------------------------------------------------------------------

/**
 * Verifies that we were
 * passed exactly 1
 * additional argument.
 */
bool validate_args(int argc) {

  if (argc != 2) {
    printf("ERROR: Only 1 additional argument accepted\n");
    return false;
  }

  return true;
}
//------------------------------------------------------------------------------

/**
 * Given an array of size 4 that represents
 * the octets in an ip address, and a struct
 * that represents the upper and lower bounds
 * of an ip address class, we return true if and
 * only if for each kth octet in ip_arr, it is
 * greater than or equal to the classes' kth lower
 * bound, and less than or each to the kth upper bound.
 */
bool within_bounds(octet_bound bounds, int* ip_arr) {
  int i;
  int upper;
  int lower;
  int octet;
  bool in_bounds = true;

  for (i = 0; i < 4; i++) {
    octet = ip_arr[i];
    lower = bounds.lower[i];
    upper = bounds.upper[i];

    // lower > octect < upper
    if (octet > upper || octet < lower) {
      in_bounds = false;
      break;
    }

    // NOTE - Debugging
    // printf("%d %d %d\n", bounds.lower[i], ip_arr[i], bounds.upper[i]);
  }

  return in_bounds;
}

//------------------------------------------------------------------------------

/**
 * Returns true if and only if
 * the string passed is a valid
 * class A, B, C or D IPv4 address.
 */
int validate_ip(char* ip_str) {
  bool  is_numeric = false;
  bool  valid      = false;
  int   octet_cnt  = 0;
  int   ip_arr[4]  = {0, 0, 0, 0};
  char *octet_str;
  char *string;
  char *tofree;

  tofree = string = strdup(ip_str);
  assert(string != NULL);

  // Convert each octet from str to int and
  // store it in the array of octets
  while ((octet_str = strsep(&string, ".")) != NULL) {

    // TODO - Figure out how to filter out letters?
    ip_arr[octet_cnt] = atoi(octet_str);
    octet_cnt++;
  }

  free(tofree);

  // Must of type
  // A, B, C or D
  if (
    within_bounds(class_A, ip_arr) ||
    within_bounds(class_B, ip_arr) ||
    within_bounds(class_C, ip_arr) ||
    within_bounds(class_D, ip_arr)
  ) {
    valid = true;
  }

  // Print appropriate string
  valid ? printf("true\n") : printf("false\n");

  return valid;
}

//------------------------------------------------------------------------------

/**
 * Small utility program that validates
 * whether or not an ip address is a valid
 * class A, B, C or D IPv4  address.
 * If the argument is a valid ip address, then
 * "true" is printed to the console along
 * with a zero exit status. If more than 1 argument
 * is passed then an error message is displayed
 * along with a non-zero exit status. If the argument
 * is not valid, "false" is printed to the console
 * with a zero exit status.
 * See - http://www.manpagez.com/man/3/strsep/
 */
int main(int argc, char *argv[]) {

  // Read in first arg
  char* ip  = argv[1];
  int   len = sizeof(ip) / sizeof(char);

  // Valid # of args, if good validate the ip address.
  return validate_args(argc) && validate_ip(ip) ? 0 : 1;
}
