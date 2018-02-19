#include "../include/sort_ips.h"

//------------------------------------------------------------------------------

/**
 * Sorts a list of ip
 * addresses in ascending order
 */
int main(int argc, char* argv[]) {

  // Validate list of ips, if it's good, sort and print them
  return valid_ip_list(argv, argc) && sort_ips(argc, argv) ? 0 : 1;
}
