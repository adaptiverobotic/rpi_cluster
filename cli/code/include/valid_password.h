#ifndef VALID_PASSWORD_H
#define VALID_PASSWORD_H

#include "util.h"

// Min and max password name length
static const int MIN_LEN = 8;
static const int MAX_LEN = 26;

/**
 * Makes sure the password is
 * one of the printable characters
 * on american keyboard. No whitespace
 * allowed.
 */
bool valid_pass(char* pass) {
  bool valid = false;
  int len    = strlen(pass);
  int i;
  int j;

  // At least length 2
  if (len < MIN_LEN) {
    fprintf(stderr, "Password must contain at least 8 characters\n");
    return false;
  }

  // At most length 26
  if (len > MAX_LEN) {
    fprintf(stderr, "Password must contain no more than 26 characters\n");
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
      if (pass[i] == VALID_CHARS[j]) {
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
