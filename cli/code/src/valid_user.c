#include "../include/valid_user.h"

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
  return validate_args(argc, 2) && valid_user(user) ? 0 : 1;
}
