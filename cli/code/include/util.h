#ifndef UTIL_H
#define UTIL_H


typedef int bool;
#define true 1
#define false 0

//------------------------------------------------------------------------------

// Numbers as chars
static const char numbers[] = {
  '0', '1', '2', '3', '4',
  '5', '6', '7', '8', '9'
};

//------------------------------------------------------------------------------

/**
 * Returns true if
 * and only if the string
 * passed represents an int
 */
bool is_numeric(char c) {
  int i;
  bool is_num = false;

  for (i = 0; i < 10; i++) {
    if (c == numbers[i]) {
      is_num = true;
      break;
    }
  }

  return is_num;
}

#endif
