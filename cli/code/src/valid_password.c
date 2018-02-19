#include "../include/valid_password.h"


/**
 * Validates passwords. Must be between 8 and
 * 26 characters inclusive, a continuous string
 * of non-whitespace ASCII characters.
 * We have stricter rules just to make
 * sure the password works for all cases (linux, apps, etc).
 */
int main(int argc, char* argv[]) {
  char* pass = argv[1];

  // Vaidate # of args, if good, validate password
  return validate_args(argc, 2) && valid_pass(pass) ? 0 : 1;
}
