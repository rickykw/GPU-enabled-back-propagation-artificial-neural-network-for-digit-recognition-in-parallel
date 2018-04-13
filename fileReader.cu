#include "fileReader.h"


void FileReader::readImageFile( unsigned char *data ){
  input_file = fopen("train-images.idx3-ubyte", "r");
  CHECK_NOTNULL(input_file);
  CHECK(fread(magic_number_bytes, sizeof(char), 4, input_file));

  /*************************************/

  // If MSB is first then magic_number_bytes will be 0x00000803
  if (magic_number_bytes[2] == 0x08 && magic_number_bytes[3] == 0x03) {
    LOG_INFO("Little Endian : MSB first");
  } else if (magic_number_bytes[0] == 0x01 && magic_number_bytes[1] == 0x08) {
    // I haven't taken into account big indian-ness, yet.
    LOG_FATAL("Big Endian : MSB last");
  } else {
    LOG_FATAL("This doesn't correspond to a MNIST Label file.");
  }

  /*************************************/

  LOG_INFO("magic number: %d", hex_array_to_int(magic_number_bytes, 4));

  CHECK(fread(number_of_images_bytes, sizeof(char), 4, input_file));
  
  int32_t number_of_images = hex_array_to_int(number_of_images_bytes, 4);
  LOG_INFO("number of images: %d", number_of_images);

  CHECK(fread(num_row_cols, sizeof(char), 4, input_file));
  number_of_rows = hex_array_to_int(num_row_cols, 4);
  CHECK(fread(num_row_cols, sizeof(char), 4, input_file));
  number_of_columns = hex_array_to_int(num_row_cols, 4);
  LOG_INFO("pixel rows: %d and pixel columns: %d", number_of_rows, number_of_columns);

  int32_t num_pixles_in_image = number_of_columns * number_of_rows;
  unsigned char images_pixels_bytes[num_pixles_in_image];
  int images_done = 0;

   while (images_done < number_of_images) {
    CHECK(fread(images_pixels_bytes, sizeof(char), num_pixles_in_image,
                input_file     ));
    int32_t idx = 0;
    for (idx = 0; idx < num_pixles_in_image; ++idx) {
      int index = idx + num_pixles_in_image * images_done;
      
      int32_t image_pixel_value = hex_char_to_int(images_pixels_bytes[idx]);
      //if(image_pixel_value > 10){
      data[index] = images_pixels_bytes[index];
      //printf("%d--\n", data[index]);
      //}
      //else
      //data[index] = 0.0;
      
      //int char_written =
      //fprintf(output_file_pointer, "%"PRId32" ", image_pixel_value);
      //CHECK(char_written);

      // A graphic of the number this represents.
      /*
      if (idx % number_of_columns  == 0) printf("\n");
      if (image_pixel_value < 10) {
        printf(".");
      } else {
        printf("*");
      }
      
    }
    printf("\n----------------------------------------------------------\n");
      */
    }
    images_done++;
    break;
    }
   
   
    //fprintf(output_file_pointer, "\n");
  


}

void FileReader::readLabelFile(int *data){
  input_file = fopen("train-labels.idx1-ubyte", "r");

  CHECK(fread(magic_number_bytes, sizeof(char), 4, input_file));

   // If MSB is first then magic_number_bytes will be 0x00000801
  if (magic_number_bytes[2] == 0x08 && magic_number_bytes[3] == 0x01) {
    LOG_INFO("Little Endian : MSB first");
  } else if (magic_number_bytes[0] == 0x01 && magic_number_bytes[1] == 0x08) {
    // I haven't taken into account big indian-ness, yet.
    LOG_FATAL("Big Endian : MSB last");
  } else {
    LOG_FATAL("This doesn't correspond to a MNIST Label file.");
  }

  LOG_INFO("magic number: %d", hex_array_to_int(magic_number_bytes, 4));

  CHECK(fread(number_of_images_bytes, sizeof(char), 4, input_file));
  LOG_INFO("number of labels: %d", hex_array_to_int(number_of_images_bytes, 4));

  char label_byte;
  int i = 0;
   while (fread(&label_byte, sizeof(char), 1, input_file)) {
     int char_written = hex_char_to_int(label_byte);
     data[i] = char_written;
     i++;
  }
  


  
}

void FileReader::readImageFile( double *data ){
  input_file = fopen("train-images.idx3-ubyte", "r");
  CHECK_NOTNULL(input_file);
  CHECK(fread(magic_number_bytes, sizeof(char), 4, input_file));

  /*************************************/

  // If MSB is first then magic_number_bytes will be 0x00000803
  if (magic_number_bytes[2] == 0x08 && magic_number_bytes[3] == 0x03) {
    LOG_INFO("Little Endian : MSB first");
  } else if (magic_number_bytes[0] == 0x01 && magic_number_bytes[1] == 0x08) {
    // I haven't taken into account big indian-ness, yet.
    LOG_FATAL("Big Endian : MSB last");
  } else {
    LOG_FATAL("This doesn't correspond to a MNIST Label file.");
  }

  /*************************************/

  LOG_INFO("magic number: %d", hex_array_to_int(magic_number_bytes, 4));

  CHECK(fread(number_of_images_bytes, sizeof(char), 4, input_file));
  
  int32_t number_of_images = hex_array_to_int(number_of_images_bytes, 4);
  LOG_INFO("number of images: %d", number_of_images);

  CHECK(fread(num_row_cols, sizeof(char), 4, input_file));
  number_of_rows = hex_array_to_int(num_row_cols, 4);
  CHECK(fread(num_row_cols, sizeof(char), 4, input_file));
  number_of_columns = hex_array_to_int(num_row_cols, 4);
  LOG_INFO("pixel rows: %d and pixel columns: %d", number_of_rows, number_of_columns);

  int32_t num_pixles_in_image = number_of_columns * number_of_rows;
  unsigned char images_pixels_bytes[num_pixles_in_image];
  int images_done = 0;

   while (images_done < number_of_images) {
    CHECK(fread(images_pixels_bytes, sizeof(char), num_pixles_in_image,
                input_file     ));
    int32_t idx = 0;
    for (idx = 0; idx < num_pixles_in_image; ++idx) {
      int index = idx + num_pixles_in_image * images_done;
      
      int32_t image_pixel_value = hex_char_to_int(images_pixels_bytes[idx]);
      if(image_pixel_value > 10){
	data[index] = 1.0;
      //printf("%d--\n", data[index]);
      }
      else
	data[index] = 0.0;
      
      //int char_written =
      //fprintf(output_file_pointer, "%"PRId32" ", image_pixel_value);
      //CHECK(char_written);

      // A graphic of the number this represents.
      /*
      if (idx % number_of_columns  == 0) printf("\n");
      if (image_pixel_value < 10) {
        printf(".");
      } else {
        printf("*");
      }
      
    }
    printf("\n----------------------------------------------------------\n");
      */
    }
    images_done++;
    
    }
   
   
    //fprintf(output_file_pointer, "\n");
  


}

//////////////////////////////////////

void FileReader::readTestFile( double *data ){
  input_file = fopen("t10k-images.idx3-ubyte", "r");
  CHECK_NOTNULL(input_file);
  CHECK(fread(magic_number_bytes, sizeof(char), 4, input_file));

  /*************************************/

  // If MSB is first then magic_number_bytes will be 0x00000803
  if (magic_number_bytes[2] == 0x08 && magic_number_bytes[3] == 0x03) {
    LOG_INFO("Little Endian : MSB first");
  } else if (magic_number_bytes[0] == 0x01 && magic_number_bytes[1] == 0x08) {
    // I haven't taken into account big indian-ness, yet.
    LOG_FATAL("Big Endian : MSB last");
  } else {
    LOG_FATAL("This doesn't correspond to a MNIST Label file.");
  }

  /*************************************/

  LOG_INFO("magic number: %d", hex_array_to_int(magic_number_bytes, 4));

  CHECK(fread(number_of_images_bytes, sizeof(char), 4, input_file));
  
  int32_t number_of_images = hex_array_to_int(number_of_images_bytes, 4);
  LOG_INFO("number of images: %d", number_of_images);

  CHECK(fread(num_row_cols, sizeof(char), 4, input_file));
  number_of_rows = hex_array_to_int(num_row_cols, 4);
  CHECK(fread(num_row_cols, sizeof(char), 4, input_file));
  number_of_columns = hex_array_to_int(num_row_cols, 4);
  LOG_INFO("pixel rows: %d and pixel columns: %d", number_of_rows, number_of_columns);

  int32_t num_pixles_in_image = number_of_columns * number_of_rows;
  unsigned char images_pixels_bytes[num_pixles_in_image];
  int images_done = 0;

   while (images_done < number_of_images) {
    CHECK(fread(images_pixels_bytes, sizeof(char), num_pixles_in_image,
                input_file     ));
    int32_t idx = 0;
    for (idx = 0; idx < num_pixles_in_image; ++idx) {
      int index = idx + num_pixles_in_image * images_done;
      
      int32_t image_pixel_value = hex_char_to_int(images_pixels_bytes[idx]);
      if(image_pixel_value > 10){
	data[index] = 1.0;
      //printf("%d--\n", data[index]);
      }
      else
	data[index] = 0.0;
      
      //int char_written =
      //fprintf(output_file_pointer, "%"PRId32" ", image_pixel_value);
      //CHECK(char_written);

      // A graphic of the number this represents.
      /*
      if (idx % number_of_columns  == 0) printf("\n");
      if (image_pixel_value < 10) {
        printf(".");
      } else {
        printf("*");
      }
      
    }
    printf("\n----------------------------------------------------------\n");
      */
    }
    images_done++;
    
    }
   
   
    //fprintf(output_file_pointer, "\n");
  


}

void FileReader::readTestLabel(int *data){
  input_file = fopen("t10k-labels.idx1-ubyte", "r");

  CHECK(fread(magic_number_bytes, sizeof(char), 4, input_file));

   // If MSB is first then magic_number_bytes will be 0x00000801
  if (magic_number_bytes[2] == 0x08 && magic_number_bytes[3] == 0x01) {
    LOG_INFO("Little Endian : MSB first");
  } else if (magic_number_bytes[0] == 0x01 && magic_number_bytes[1] == 0x08) {
    // I haven't taken into account big indian-ness, yet.
    LOG_FATAL("Big Endian : MSB last");
  } else {
    LOG_FATAL("This doesn't correspond to a MNIST Label file.");
  }

  LOG_INFO("magic number: %d", hex_array_to_int(magic_number_bytes, 4));

  CHECK(fread(number_of_images_bytes, sizeof(char), 4, input_file));
  LOG_INFO("number of labels: %d", hex_array_to_int(number_of_images_bytes, 4));

  char label_byte;
  int i = 0;
   while (fread(&label_byte, sizeof(char), 1, input_file)) {
     int char_written = hex_char_to_int(label_byte);
     data[i] = char_written;
     i++;
  }
  


  
}