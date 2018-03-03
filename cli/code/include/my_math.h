#ifndef MY_MATH_H
#define MY_MATH_H

//------------------------------------------------------------------------------

#include "util.h"

//------------------------------------------------------------------------------

/**
 * Round a decimal number down,
 * return as int.
 */
int my_floor(double number) {
  return (int) floor(number);
}

//------------------------------------------------------------------------------

/**
 * Round a decimal number up,
 * return as int.
 */
int my_ceil(double number) {
  return (int) ceil(number);
}

#endif
