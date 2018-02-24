#ifndef VALID_HOSTNAME_H
#define VALID_HOSTNAME_H

#include "util.h"

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

#endif
