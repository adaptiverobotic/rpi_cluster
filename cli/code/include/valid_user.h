#ifndef VALID_USER_H
#define VALID_USER_H

#include "util.h"

//------------------------------------------------------------------------------

// Min and max user name length
static const int MIN_LEN = 2;
static const int MAX_LEN = 26;

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

#endif
