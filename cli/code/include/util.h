#ifndef UTIL_H
#define UTIL_H

//------------------------------------------------------------------------------

#include <string.h>  // strlen()
#include <stdio.h>  // printf()
#include <stdlib.h> // atoi()

//------------------------------------------------------------------------------

typedef int bool;
#define true 1
#define false 0

//------------------------------------------------------------------------------

// Numbers as chars
static const char numbers[] = {
  '0', '1', '2', '3', '4',
  '5', '6', '7', '8', '9'
};

// Letters in alphabet
static const char alphabet[] = {
  'a', 'b', 'c', 'd',
  'e', 'f', 'g', 'h',
  'i', 'j', 'k', 'l',
  'm', 'n', 'o', 'p',
  'q', 'r', 's', 't',
  'u', 'v', 'w', 'x',
  'y', 'z'
};

// Valid characters
static const char VALID_CHARS[] = {
  // Lower case
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
  'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
  'u', 'v', 'w', 'x', 'y', 'z',

  // Upper case
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
  'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
  'U', 'V', 'W', 'X', 'Y', 'Z',

  // Numbers
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',

  // Special characters
  '`', '~', '!', '@', '#', '$', '%', '^', '&', '*',
  '(', ')', '-', '_', '=', '+', '[', '{', ']', '}',
  '\\', '|', ';', ':', '\'', '\"', ',', '<', '.', '>',
  '/', '?'
};

//------------------------------------------------------------------------------

/**
 * Verifies that we were
 * passed exactly N
 * additional argument.
 */
bool validate_args(int argc, int arg_limit) {

  if (argc != arg_limit) {
    fprintf(stderr, "ERROR: Up to %d argument(s) accepted\n", arg_limit - 1);
    return false;
  }

  return true;
}

//------------------------------------------------------------------------------

/**
 * Returns true if
 * and only if the string
 * passed represents an int
 */
bool is_numeric(char c) {
  int i;
  bool is_num = false;

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
  return is_numeric(c) || is_a_letter(c);
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

#endif
