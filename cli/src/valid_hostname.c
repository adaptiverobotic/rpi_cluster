#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Declare booleans
// because C doesn't
// have them
typedef int bool;
#define true 1
#define false 0

// Letters in alphabet
char alphabet[] = {
  'a', 'b', 'c', 'd',
  'e', 'f', 'g', 'h',
  'i', 'j', 'k', 'l',
  'm', 'n', 'o', 'p',
  'q', 'r', 's', 't',
  'u', 'v', 'w', 'x',
  'y', 'z'
};

// The numbers as chars
char numbers[] = {
  '0', '1', '2', '3', '4',
  '5', '6', '7', '8', '9'
};

//------------------------------------------------------------------------------

/*
 * Ensure only 1 arg was passed.
 */
bool valid_args(int argc) {

  if (argc != 2) {
    printf("ERROR: Only 1 argumet permitted.\n");
    return false;
  }

  return true;
}

//------------------------------------------------------------------------------

// Returns true if an only
// if the char passed is
// a numeric character
bool is_a_number(char c) {
  bool is_num = false;
  int i;

  // Cross check against each num
  for (i = 0; i < 10; i++) {
    if (c == numbers[i]) {
      is_num = true;
      break;
    }
  }

  return is_num;
}

//------------------------------------------------------------------------------

// Returns true if an only
// if the char passed is
// a member of lowercase alphabet
bool is_a_letter(char c) {
  bool is_letter = false;
  int i;

  // Cross check against each num
  for (i = 0; i < 26; i++) {
    if (c == alphabet[i]) {
      is_letter= true;
      break;
    }
  }

  return is_letter;
}

//------------------------------------------------------------------------------

/**
 * Returns true if and only if
 * the argument is a lowercase
 * letter or a number
 */
bool is_alpha_numeric(char c) {
  return is_a_number(c) || is_a_letter(c);
}

//------------------------------------------------------------------------------

/**
 * Returns true if and only if
 * hostname contains only letters
 * and hyphens.
 */
bool valid_hostname(char* hostname) {
  bool valid = true;
  int len    = strlen(hostname);
  int i;

  // Validate each char in string
  for (i = 0; i < len; i++) {

    // Two non-alphanumeric values
    // cannot follow each other
    if (
      i != len-1 &&
      !is_alpha_numeric(hostname[i]) &&
      !is_alpha_numeric(hostname[i+1])
    ) {
      valid = false;
      break;
    }

    // Must be a letter,
    // number, or hyphen,
    // or a period
    if (
      !is_alpha_numeric(hostname[i]) &&
      hostname[i] != '-'             &&
      hostname[i] != '.'
    ) {
      valid = false;
      break;
    }

    // Cannot begin or end in period
    // or hyphen - must be alphanumeric
    if (
      (i == 0 || i == len-1) &&
      !is_alpha_numeric(hostname[i]))  {
      valid = false;
      break;
    }
  }

  // Print whether or not the hostname is valid
  valid ? printf("true\n") : printf("false\n");

  return valid;
}

//------------------------------------------------------------------------------

/**
 * Utility to validate a hostname.
 * Hostnames must be strings with
 * all alphanumeric values with optional
 * hyphens and periods. The hostname may
 * not begin or end with a hyphen or period.
 * There cannot be two non-alphanumeric
 * characters in a row. Example, '--' or
 * '-.' are not allowed.
 */
int main(int argc, char* argv[]) {

  char* hostname = argv[1];

  // Validate # of args, if good, validate the hostname
  return valid_args(argc) && valid_hostname(hostname) ? 0 : 1;
}
