#include "../include/valid_hostname.h"

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
  return validate_args(argc, 2) && valid_hostname(hostname) ? 0 : 1;
}
