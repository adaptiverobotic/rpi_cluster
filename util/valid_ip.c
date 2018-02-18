#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

// Declare booleans
// because C doesn't
// have them
typedef int bool;
#define true 1
#define false 0

// Forward declaration of our struct
typedef struct octet_bound octet_bound;

// Struct that represents the lower
// and upper bounds of a
// given IPv4 address class
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

// The numbers as characters
static char numbers[] = {
  '0', '1', '2', '3', '4',
  '5', '6', '7', '8', '9'
};

// TODO - @ some later date
// expand to add another arg, that
// way, if the user wants to check
// if an ip address is of a specific
// class, that's an option. Otherwise,
// check all.

// Number of required args
static int arg_limit = 2;

//------------------------------------------------------------------------------

/**
 * Verifies that we were
 * passed exactly N
 * additional argument.
 */
bool validate_args(int argc) {

  if (argc != arg_limit) {
    printf("ERROR: Up to %d argument(s) accepted\n", arg_limit - 1);
    return false;
  }

  return true;
}

//------------------------------------------------------------------------------

/*
 * Returns true if and only
 * if a string passed contains
 * only numeric values
 */
bool is_numeric(char* ip) {
  int i    = 0;
  int j    = 0;
  int n    = strlen(ip);
  bool num = false;

  // Loop through each char
  while (i < n) {
    num = false;

    // Loop through array of nums
    for (j = 0; j < 10; j++) {
      if (ip[i] == numbers[j]) {
        num = true;
        break;
      }
    }

    // If a non-number
    // was found, break
    if (!num) {
      break;
    }

    i++;
  }

  return num;
}

//------------------------------------------------------------------------------

/**
 * Given an array of size 4 that represents
 * the octets in an ip address, and a struct
 * that represents the upper and lower bounds
 * of an ip address class, we return true if and
 * only if for each kth octet in ip_arr, it is
 * greater than or equal to the specified classes' kth lower
 * bound, and less than or equal to the kth upper bound.
 */
bool within_bounds(octet_bound bounds, int* ip_arr) {
  int i;
  int upper;
  int lower;
  int octet;
  bool in_bounds = true;

  // Loop through each octet
  for (i = 0; i < 4; i++) {
    octet = ip_arr[i];
    lower = bounds.lower[i];
    upper = bounds.upper[i];

    // lower >= octect <= upper
    if (octet > upper || octet < lower) {
      in_bounds = false;
      break;
    }
  }

  return in_bounds;
}

//------------------------------------------------------------------------------

/*
 * Returns true if and only
 * if the string passed has
 * leading zeros. Example "001"
 */
bool has_leading_zeros(char* ip) {
  if (strlen(ip) > 1 && ip[0] == '0') {
    return true;
  }

  return false;
}

//------------------------------------------------------------------------------

/**
 * Returns true if and only if
 * the string passed is a valid
 * class A, B, C or D IPv4 address.
 */
int validate_ip(char* ip_str) {
  bool  numeric   = true;
  bool  valid     = false;
  int   octet_cnt = 0;
  int   ip_arr[4] = {0, 0, 0, 0};
  char *octet_str;
  char *string;
  char *tofree;

  // Copy the string
  tofree = string = strdup(ip_str);

  // Make sure it's not empty
  assert(string != NULL);

  /*
   * 1. Separate each octect by separating
   *    what's between each dot.
   *
   * 2. Convert each octet to an integer
   *    and store it in the array of octets
   */
  while ((octet_str = strsep(&string, ".")) != NULL) {

    // Make sure we only have numbers in our octets.
    // A number with a leading zero does not count.
    if (!is_numeric(octet_str) || has_leading_zeros(octet_str)) {
        numeric = false;
        break;
    }

    ip_arr[octet_cnt] = atoi(octet_str);

    // Increment number
    // of octets that we
    // have processed
    octet_cnt++;
  }

  // Let it gooo!
  // let it GoOoO!
  // jk, don't jack that...
  free(tofree);

  // Valid imples the string contains only
  // numbers with exactly dots 4 separating
  // dots, and be of class A, B, C, or D
  if (
    octet_cnt == 4 &&
    numeric && (
    within_bounds(class_A, ip_arr) ||
    within_bounds(class_B, ip_arr) ||
    within_bounds(class_C, ip_arr) ||
    within_bounds(class_D, ip_arr)
    )) {
    valid = true;
  }

  // Print whether or not it's valid
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
 * NOTE - LEADING ZEROS ARE NOT ALLOWED. THAT IS
 * BECAUSE WE ARE TAKING INTO ACCOUNT THE PURPOSE
 * OF THIS PROGRAM IN THE LARGER ECOSYSTEM. BUT,
 * IN PRACTICE, THEY ARE FINE (FOR MOST THINGS).
 * See - http://www.manpagez.com/man/3/strsep/
 */
int main(int argc, char *argv[]) {

  // Read in first arg
  char* ip  = argv[1];

  // Validate # of args, if valid, validate the ip address.
  return validate_args(argc) && validate_ip(ip) ? 0 : 1;
}
