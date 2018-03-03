#include "../include/my_math.h"

//------------------------------------------------------------------------------

/**
 * Match arg func_name and the appropriate
 * function to call.
 */
bool switch_func(char* func_name, double num) {

  // Round up
  if (strcmp(func_name, "ceil") == 0) {
    printf("%d\n", my_ceil(num));
    return true;

  // Round down
  } else if (strcmp(func_name, "floor") == 0) {
    printf("%d\n", my_floor(num));
    return true;
  }

  // Print error message if func name not recognized
  printf("ERROR: Function name '%s' not recognized. 'ceil' and 'floor' accepted\n", func_name);

  return false;
}

//------------------------------------------------------------------------------

/**
 * Rounds numbers up or down.
 * Non-numeric strings
 * always resolve to zero.
 */
int main(int argc, char* argv[]) {

  return validate_args(argc, 3) &&
         switch_func(argv[1], atof(argv[2])) ? 0 : 1;
}
