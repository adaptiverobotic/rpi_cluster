#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Declare booleans
// because C doesn't
// have them
typedef int bool;
#define true 1
#define false 0

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

// Min and max user name length
static const int MIN_LEN = 2;
static const int MAX_LEN = 26;

//------------------------------------------------------------------------------

// Make sure we only got
// 1 addition argument
bool valid_args(int argc) {
  if (argc != 2) {
    fprintf(stderr, "ERROR: Only 1 addition argument accepted\n");
    return false;
  }

  return true;
}

//------------------------------------------------------------------------------

// Returns true if and only
// if the char passed is a letter
bool is_a_letter(char c) {
  bool valid = false;
  int i;

  // Loop through lower and
  // upper case letters, and
  // cross check against each one
  for (i = 0; i < 52; i++) {
    if (c == VALID_CHARS[i]) {
      valid = true;
      break;
    }
  }

  return valid;
}

//------------------------------------------------------------------------------

/**
 * Makes sure the username is
 * one of the printable characters
 * on american keyboard. No whitespace
 * allowed.
 */
bool valid_user(char* user) {
  bool valid = false;
  int len    = strlen(user);
  int i;
  int j;

  // Must start with a letter
  if (!is_a_letter(user[0])) {
    fprintf(stderr, "User must begin with a letter\n");
    return false;
  }

  // At least length 2
  if (len < MIN_LEN) {
    fprintf(stderr, "User must contain at least 2 characters\n");
    return false;
  }

  // At most length 26
  if (len > MAX_LEN) {
    fprintf(stderr, "User must contain no more than 26 characters\n");
    return false;
  }

  // Loop through full string
  for (i = 0; i < len; i++) {
    valid = false;

    // Check each char against
    // all valid chars. At least
    // one must come back true
    // to continue
    for (j = 0; j < 94; j++) {

      // Break on first valid char
      if (user[i] == VALID_CHARS[j]) {
        valid = true;
        break;
      }
    }

    // If valid still
    // false, the char
    // was not recognized,
    // so we break
    if (!valid) {
      break;
    }
  }

  // Print appropriate string
  valid ? printf("true\n") : printf("false\n");

  return valid;
}

//------------------------------------------------------------------------------

/**
 * Validates usernames. Must be between 2 and
 * 26 characters inclusive, a continuous string
 * of non-whitespace ASCII characters, and begin
 * with a letter. We have stricter rules just to make
 * sure the user works for all cases (linux, apps, etc).
 */
int main(int argc, char* argv[]) {
  char* user = argv[1];

  // Vaidate # of args, if good, validate user
  return valid_args(argc) && valid_user(user) ? 0 : 1;
}
