#include "../include/valid_ipv4.h"

//------------------------------------------------------------------------------

/**
 * Small utility program that validates
 * whether or not an ip address is a valid
 * class A, B, C or D IPv4  address.
 * If the argument is a valid ip address, then
 * "true" is printed to the console along
 * with a zero exit status. If more than 1 argument
 * is passed then an error message is displayed
 * along with a non-zero exit status. If the argument
 * is not valid, "false" is printed to the console
 * with a zero exit status.
 * NOTE - LEADING ZEROS ARE NOT ALLOWED. THAT IS
 * BECAUSE WE ARE TAKING INTO ACCOUNT THE PURPOSE
 * OF THIS PROGRAM IN THE LARGER ECOSYSTEM. BUT,
 * IN PRACTICE, THEY ARE FINE (FOR MOST THINGS).
 * See - http://www.manpagez.com/man/3/strsep/
 */
int main(int argc, char *argv[]) {

  // Read in first arg
  char* ip  = argv[1];

  // Validate # of args, if valid, validate the ip address.
  return validate_args(argc) && validate_ip(ip) ? 0 : 1;
}
