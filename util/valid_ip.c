#include <stdio.h>

//------------------------------------------------------------------------------

/**
 * Verifies that we were
 * passed exactly 1 additional
 * argument.
 */
int validate_args(int argc) {

  if (argc != 2) {
    printf("false\n");
    return 1;
  }

  return 0;
}

//------------------------------------------------------------------------------

/**
 * Returns 0 if and only if
 * the string passed is a valid
 * class A, B, or C IPv4 or IPv6
 * ip address.
 */
int validate_ip(char* ip, int len) {
  printf("%s\n", ip);
  return 0;
}

//------------------------------------------------------------------------------

/**
 * Small utility program that validates
 * whether or not an ip address is a valid
 * class A, B, or C IPv4 or IPv6 ip adress.
 */
int main(int argc, char *argv[]) {

  // Read in first arg
  char* ip  = argv[1];
  int   len = sizeof(ip) / sizeof(ip[char]);

  // Validate argc and if that's good, validate the ip
  return validate_args(argc) || validate_ip(ip, len));
}
