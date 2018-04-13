MAKEFILE      = Makefile
####### Compiler, tools and options
NVCC 	      = nvcc
CC            = gcc
CXX           = g++
DEL_FILE      = rm -f
LINK          = nvcc

####### Files

OBJECTS       =  main.o hex_lib.o fileReader.o
TARGET        =  GPUNeuralNetwork


GPUNN: all
####### Implicit rules

.SUFFIXES: .o .c .cpp .cc .cxx .C .cu 

.cpp.o:
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o "$@" "$<"

.cc.o:
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o "$@" "$<"

.cxx.o:
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o "$@" "$<"

.C.o:
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o "$@" "$<"

.c.o:
	$(CC) -c $(CFLAGS) $(INCPATH) -o "$@" "$<"
.cu.o:
	$(NVCC) -c $(CFLAGSNVCC) $(INCPATHNVCC) -o "$@" "$<"

####### Build rules

$(TARGET):  $(OBJECTS)  
	$(LINK) -o $(TARGET) $(OBJECTS)

all: Makefile $(TARGET)

clean:compiler_clean 
	-$(DEL_FILE) *.o GPUNeuralNetwork

####### Sub-libraries

compiler_clean: 
