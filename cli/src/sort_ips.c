#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Declare booleans
// because C doesn't
// have them
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

// Validate the list
bool valid_ip_list(char* ips[], int len) {
  int i;
  bool valid = true;

  // Check each ip
  for (i = 0; i < len; i++) {

    // Break on first
    // invalid ip
    if (false) {
      valid = false;
      break;
    }

    // printf("%s\n", ips[i]);
  }

  return valid;
}

//------------------------------------------------------------------------------

void swap() {
  ;
}

//------------------------------------------------------------------------------

/**
 * Sorts arrya in place
 */
void sort(int* ip_ints, int len) {
  ;
}


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

//------------------------------------------------------------------------------

/**
 * Remove all non-numeric
 * values from a string and
 * returns a pointer to new
 * string with only numbers
 */
char* remove_dots(char* ip_str) {
  int   i;
  int   j;
  int   len     = strlen(ip_str);
  char* new_str = (char*) malloc(len * sizeof(char));

  // Loop through old string
  for (i = 0; i < len; i++) {

    // Only move numeric
    // values to new str
    if (is_numeric(ip_str[i])) {
        new_str[j] = ip_str[i];
        j++;
    }
  }

  // Null terminate it
  new_str[j] = '\0';

  return new_str;
}

//------------------------------------------------------------------------------

/**
 * Converts array of ip
 * strings to array of
 * integers (without dots)
 */
int* to_int_arr(char* ip_char_arr[], int len) {
  int*  ip_int_arr = (int*) malloc(len * sizeof(int));
  int   i;
  int   ip;
  char* no_dots;

  for (i = 1; i < len; i++) {

    // Get the string without dots
    no_dots = remove_dots(ip_char_arr[i]);

    // Convert to int
    ip = atoi(no_dots);

    // Store in array
    ip_int_arr[i-1] = ip;
  }

  // Free back to OS
  free(no_dots);

  return ip_int_arr;
}

//------------------------------------------------------------------------------

/**
 * Extracts the first
 * arg from command line
 * arguments, and returns
 * only the ones we want to
 * operate on.
 */
char** get_args(int argc, char* argv[]) {

  // Allocate # of rows
  char** new_argv = malloc((argc - 1) * sizeof(char*));
  int i;
  int s;

  // Allocate individual row
  for (i = 1; i < argc; i++) {
    s = sizeof(argv[i]);
    new_argv[i-1] = malloc(s * sizeof(char));
    new_argv[i-1] = argv[i];
  }

  return new_argv;
}

//------------------------------------------------------------------------------

/**
 * Sorts a list of ip
 * addresses in ascending order
 */
int main(int argc, char* argv[]) {
  bool  valid_list = valid_ip_list(argv, argc);
  int   len        = argc-1;
  int*  ips        = to_int_arr(argv, argc);
  char** strs = get_args(argc, argv);

  int i;
  for (i=0; i < argc-1; i++) {
    printf("%d\n", ips[i]);
    printf("%s\n", strs[i]);
  }

  // Get ips a int array
  ips = to_int_arr(argv, argc);


  // Free back to OS
  free(ips);

  return 0;
}
