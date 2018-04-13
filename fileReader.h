#include <stdio.h>
#include <stdint.h>
#include "macros.h"
#include "hex_lib.h"
#include <unistd.h>

#include <inttypes.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>


class FileReader{
 public:
  void readImageFile(unsigned char *data); //Read file and store contents in data array
  void readLabelFile(int *data);
  void readImageFile(double *data); //Read file and store contents in data array
  void readTestFile(double *data);
  void readTestLabel(int *data);

 private:
  FILE *input_file;
  char magic_number_bytes[4];
  char number_of_images_bytes[4];
  int32_t number_of_images;
  int32_t number_of_rows;
  int32_t number_of_columns;
  char num_row_cols[4];

};
