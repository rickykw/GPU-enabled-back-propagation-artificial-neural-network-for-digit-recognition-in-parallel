
#define INPUT_SIZE 784
#define HIDDEN_SIZE 256 //512//128//256//512 //533
#define OUTPUT_SIZE 10
#define TOTAL_IMAGES 60000
#define NORMALIZING_CONSTANT 0.00392156
#define MOMENTUM 0.9
#define TEACHING_STEP 0.1


#include "fileReader.h"
#include <cstdlib>
#include <iostream>
#include "common.h"

using namespace std;

double randomValue(){
  
 double f = (double)rand() / RAND_MAX;
  return -0.25 + f * (0.25 - (-0.25));
  
}

void initializeHiddenBiases(double *weightsVector){

  for(int j = 0; j < HIDDEN_SIZE; j++){
    weightsVector[j] = randomValue();
  }
  
}

void initializeOutputBiases(double *weightsVector){

  for(int j = 0; j < OUTPUT_SIZE; j++){
    weightsVector[j] = randomValue();
  }
  
}


void initializeInputWeights(double *weightsVector){

  for(int j = 0; j < HIDDEN_SIZE; j++)
    for(int i = 0; i < INPUT_SIZE; i++){
      
      int index = i + INPUT_SIZE * j;
      weightsVector[index] = randomValue();
      //prevInputWeights[index] = weightsVector[index];
      //cout << weightsVector[index] << endl;
    }
  
}


void printImage(double *image){
  int num_pixels_in_image = 784;
  for(int i = 0; i < 10000; i++){
    for (int idx = 0;  idx < num_pixels_in_image; ++idx) {
      int index = idx + num_pixels_in_image * i;
      if (idx % 28  == 0) printf("\n");
      if (image[index] == 1.0) {
	printf("*");
      } else {
        printf(".");
      }
      
    }
    printf("\n----------------------------------------------------------\n");

  }
}

__global__ void devicePrint(double *image){
  int num_pixels_in_image = 784;
  for(int i = 9990; i < 10000; i++){
    for (int idx = 0;  idx < num_pixels_in_image; ++idx) {
      int index = idx + num_pixels_in_image * i;
      if (idx % 28  == 0) printf("\n");
      if (image[index] == 1.0) {
	printf("*");
      } else {
        printf(".");
      }
      
      }
    
    printf("\n----------------------------------------------------------\n");
    }
    
}

__global__ void devicePrintWeights(double *weightsVector){
   for(int j = 0; j < 533; j++)
    for(int i = 0; i < 784; i++){
      
      int index = i + 784 * j;
      
      printf("%f\n", weightsVector[index]);
    }
}

void initializeOutputWeights(double *weightsVector){

  for(int j = 0; j < OUTPUT_SIZE; j++)
    for(int i = 0; i < HIDDEN_SIZE; i++){
      
      int index = i + HIDDEN_SIZE * j;
      weightsVector[index] = randomValue();
      //prevOutputWeights[index] = weightsVector[index];
      //cout << weightsVector[index] << endl;
    }
  
}

__global__ void deviceOutputWeights(double *weights){

  int j = blockIdx.x;
  int i = threadIdx.x;
  int size = blockDim.x;
  int index = i + j * size;

  printf("gpu %f\n", weights[index]);


}

__global__ void printLabel(int * labelData){

  int i = threadIdx.x;

  printf("GPU label %d\n", labelData[i]);
  
}

/************************************************************************************************/

__device__ double sigmoidal(double x){
  return 1.0 / (1.0 + exp(-x));
}

__device__ double derSigmoidal(double x){
  return x * (1 - x);
}

__global__ void feedForwardIH(double *inputNodes, double *hiddenNodes, double *hiddenWeights, int k, double *hiddenBiases){

  int j = blockIdx.x;
  int i = threadIdx.x;
  int size = blockDim.x;
  int weightIndex = i + size*j;
  int inputIndex = i + size*k;
  __shared__ double temp[784];

  temp[i] = inputNodes[inputIndex] * hiddenWeights[weightIndex];

  __syncthreads();

  
  
  for(int stride = 1; stride < blockDim.x; stride *=2){
    int index2 = 2 * stride * i;
    if(index2 < blockDim.x && index2 + stride < blockDim.x){
      temp[index2] += temp[index2 + stride];
    }

    __syncthreads();
  }
  
  
  if(i == 0){
    hiddenNodes[j] = temp[0];
    //hiddenNodes[j] += hiddenBiases[j];
    hiddenNodes[j] = sigmoidal(hiddenNodes[j]);
  }
  
}

__global__ void feedForwardHO(double *hiddenNodes, double *outputNodes, double *outputWeights, double *outputBiases){

  int j = blockIdx.x;
  int i = threadIdx.x;
  int size = blockDim.x;
  int weightIndex = i + size*j;

  __shared__ double temp[HIDDEN_SIZE];

  temp[i] = hiddenNodes[i] * outputWeights[weightIndex];

  __syncthreads();

  //parallel reduction

  int m = blockDim.x/2;

  while(m != 0) {
    if(threadIdx.x < m)
      temp[threadIdx.x] += temp[threadIdx.x + m];
    __syncthreads();
    m /= 2;
  }

  if(threadIdx.x == 0){
    outputNodes[j] = temp[0];// + outputBiases[j];
    outputNodes[j] = sigmoidal(outputNodes[j]);
  }

}

__global__ void calcDeltas(double *outputNodes, double *outputDeltas, int* target, int k, double *hiddenDeltas, double *hiddenNodes, double *outputWeights){

  int index = threadIdx.x + blockIdx.x * blockDim.x;

  if(index < 10){

    if(index != target[k]){
      outputDeltas[index] = (0.0 - outputNodes[index]);
    }
    else{
      outputDeltas[index] = (1.0 - outputNodes[index]);
    }
    //printf("GPU output delta %f\n", outputNodes[index]);
  }
  __syncthreads();

  hiddenDeltas[index] = 0;
  for(int z = 0; z < 10; z++){
    hiddenDeltas[index] += outputDeltas[z] * outputWeights[index+HIDDEN_SIZE*z]; 
  }
  hiddenDeltas[index] *= derSigmoidal(hiddenNodes[index]);
  //printf("GPU hidden delta %f\n", hiddenNodes[index]);

}

__global__ void updateInputWeights(double *hiddenWeights, double *hiddenDeltas, double *inputNodes, int k, double *prevHiddenWeights, double *tempHiddenWeights){
  double teachingStep = 0.01;
  double momentum = 0.9;
  int j = blockIdx.x;
  int i = threadIdx.x;
  int size = blockDim.x;
  int inputIndex = i + k*size;
  int weightIndex = i + j*size;

  tempHiddenWeights[weightIndex] = hiddenWeights[weightIndex];
  
  hiddenWeights[weightIndex] += teachingStep * hiddenDeltas[j] * inputNodes[inputIndex] + momentum * (hiddenWeights[weightIndex] - prevHiddenWeights[weightIndex]);

  prevHiddenWeights[weightIndex] = tempHiddenWeights[weightIndex];
}



__global__ void updateOutputWeights(double *outputWeights, double *outputDeltas, double *hiddenNodes, double *prevOutputWeights, double *tempOutputWeights){

  double teachingStep = 0.01;
  double momentum = 0.9;
  int j = blockIdx.x;
  int i = threadIdx.x;
  int size = blockDim.x;
  int weightIndex = i + j*size;

  tempOutputWeights[weightIndex] = outputWeights[weightIndex];
  
  outputWeights[weightIndex] += teachingStep * outputDeltas[j] * hiddenNodes[i] + momentum * (outputWeights[weightIndex] - prevOutputWeights[weightIndex]);

  prevOutputWeights[weightIndex] = tempOutputWeights[weightIndex];
}

__global__ void updateBiases(double *hiddenBiases, double *outputBiases, double* outputDeltas, double* hiddenDeltas, double *prevHiddenBiases, double *tempHiddenBiases, double *prevOutputBiases, double *tempOutputBiases){

  double teachingStep = 0.01;
  double momentum = 0.9;
  int i = threadIdx.x;

  if(i < 10){

    tempOutputBiases[i] = outputBiases[i];
    
    outputBiases[i] += teachingStep*outputDeltas[i] + momentum * (outputBiases[i] - prevOutputBiases[i]);

    prevOutputBiases[i] = tempOutputBiases[i];
  }

  tempHiddenBiases[i] = hiddenBiases[i];
  
  hiddenBiases[i] += teachingStep*hiddenDeltas[i] + momentum *(hiddenBiases[i] - prevHiddenBiases[i]);

  prevHiddenBiases[i] = tempHiddenBiases[i];
}

__device__ int max(double *outputNodes){
  double max = outputNodes[0];
  int maxIndex = 0;
  for(int i = 0; i < 10; i++){
    if(outputNodes[i] > max){
      max = outputNodes[i];
      maxIndex = i;
    }
  }
  return maxIndex;
}

__global__ void checkResult(double *outputNodes, int *testLabel, int k, int *count){
  //if(*count == 0)
  //printf("%d\n count", *count);
  int index = max(outputNodes);
  if(index == testLabel[k])
    *count = *count + 1;

}


int main(int argc, char *argv[])
{
  srand(time(NULL));
  //////////////////////////////////////INPUT//////////////////////////////////////////////////////
  
  double *inputData;
  inputData = (double*)malloc(INPUT_SIZE * TOTAL_IMAGES * sizeof(double));

  int *labelData;
  labelData = (int*)malloc(TOTAL_IMAGES * sizeof(int));
  
  FileReader data;
  data.readImageFile(inputData);
  data.readLabelFile(labelData);

  //alocating label data in gpu
  int *devLabelData;
  cudaMalloc((void**)&devLabelData, TOTAL_IMAGES * sizeof(int));
  cudaMemcpy(devLabelData, labelData, TOTAL_IMAGES * sizeof(int), cudaMemcpyHostToDevice);
  
  
  //alocating input in gpu
  double *devInputData;
  if(cudaSuccess != cudaMalloc((void**)&devInputData, INPUT_SIZE * TOTAL_IMAGES * sizeof(double)))
    printf("Error alocating input in gpu");

  //alocating hidden layer in gpu
  double *devHiddenNodes;
  if(cudaSuccess != cudaMalloc((void**)&devHiddenNodes, INPUT_SIZE*HIDDEN_SIZE*sizeof(double)))
    printf("Error alocating hiddenNodes in gpu");

  //alocating output layer in gpu
  double *devOutputNodes;
  if(cudaSuccess != cudaMalloc((void**)&devOutputNodes, OUTPUT_SIZE*HIDDEN_SIZE*sizeof(double)))
    printf("Error alocating output in gpu");

  //alocating hidden deltas on gpu
  double *devHiddenDeltas;
  if(cudaSuccess != cudaMalloc((void**)&devHiddenDeltas, HIDDEN_SIZE*sizeof(double)))
    printf("Error alocating hidden deltas in gpu");

  //alocating output deltas on gpu

  double *devOutputDeltas;
  if(cudaSuccess != cudaMalloc((void**)&devOutputDeltas, OUTPUT_SIZE*sizeof(double)))
    printf("Error alocating output deltas in gpu");
  
  
  if(cudaSuccess != cudaMemcpy(devInputData, inputData, INPUT_SIZE * TOTAL_IMAGES * sizeof(double), cudaMemcpyHostToDevice)){
    printf("Error copying input Data");
  }

  ///////////////////////////////////////HIDDEN WEIGHTS///////////////////////////////////////////

  //alocating and initializing hidden weights
  
  double *hiddenWeights;
  hiddenWeights = (double*)malloc(INPUT_SIZE*HIDDEN_SIZE*sizeof(double));

  initializeInputWeights(hiddenWeights);
  
  
  //alocating hidden weights in gpu
  double *devHiddenWeights;
  cudaMalloc((void**)&devHiddenWeights, INPUT_SIZE*HIDDEN_SIZE*sizeof(double));

  if(cudaSuccess != cudaMemcpy(devHiddenWeights, hiddenWeights, INPUT_SIZE*HIDDEN_SIZE*sizeof(double), cudaMemcpyHostToDevice)){
    printf("Error copying hidden weights");
  }

  double *devTempHiddenWeights;
  cudaMalloc((void**)&devTempHiddenWeights, INPUT_SIZE*HIDDEN_SIZE*sizeof(double));

  double *devPrevHiddenWeights;
  cudaMalloc((void**)&devPrevHiddenWeights, INPUT_SIZE*HIDDEN_SIZE*sizeof(double));
  if(cudaSuccess != cudaMemcpy(devPrevHiddenWeights, hiddenWeights, INPUT_SIZE*HIDDEN_SIZE*sizeof(double), cudaMemcpyHostToDevice)){
    printf("Error copying prev hidden weights");
  }

  //////////////////////////////////////////OUTPUT WEIGHTS////////////////////////////////////////

  
  //alocating and initializing output weights
  double *outputWeights;
  outputWeights = (double*)malloc(OUTPUT_SIZE*HIDDEN_SIZE*sizeof(double));

  initializeOutputWeights(outputWeights);

  //alocating output weights in gpu

  double *devOutputWeights;
  cudaMalloc((void**)&devOutputWeights, OUTPUT_SIZE*HIDDEN_SIZE*sizeof(double));

  if(cudaSuccess != cudaMemcpy(devOutputWeights, outputWeights, OUTPUT_SIZE*HIDDEN_SIZE*sizeof(double), cudaMemcpyHostToDevice)){
    printf("Error copying output weights");
  }

  double *devTempOutputWeights;
  cudaMalloc((void**)&devTempOutputWeights, OUTPUT_SIZE*HIDDEN_SIZE*sizeof(double));

  double *devPrevOutputWeights;
  cudaMalloc((void**)&devPrevOutputWeights, OUTPUT_SIZE*HIDDEN_SIZE*sizeof(double));
  if(cudaSuccess != cudaMemcpy(devPrevOutputWeights, outputWeights, OUTPUT_SIZE*HIDDEN_SIZE*sizeof(double), cudaMemcpyHostToDevice)){
    printf("Error copying prev output weights");
  }

  
  

  ////////////////////////////////////////HIDDEN BIASES////////////////////////////////////////////

  double *hiddenBiases;
  hiddenBiases = (double*)malloc(HIDDEN_SIZE*sizeof(double));
  initializeHiddenBiases(hiddenBiases);

  double *devHiddenBiases;
  cudaMalloc((void**)&devHiddenBiases, HIDDEN_SIZE*sizeof(double));
  cudaMemcpy(devHiddenBiases, hiddenBiases, HIDDEN_SIZE*sizeof(double), cudaMemcpyHostToDevice);

  double *devPrevHiddenBiases;
  cudaMalloc((void**)&devPrevHiddenBiases, HIDDEN_SIZE*sizeof(double));
  cudaMemcpy(devPrevHiddenBiases, hiddenBiases, HIDDEN_SIZE*sizeof(double), cudaMemcpyHostToDevice);
  
  double *devTempHiddenBiases;
  cudaMalloc((void**)&devTempHiddenBiases, HIDDEN_SIZE*sizeof(double));
  
  

  /////////////////////////////////////////OUTPUT BIASES///////////////////////////////////////////

  double *outputBiases;
  outputBiases = (double*)malloc(OUTPUT_SIZE*sizeof(double));
  initializeOutputBiases(outputBiases);

  double *devOutputBiases;
  cudaMalloc((void**)&devOutputBiases, OUTPUT_SIZE*sizeof(double));
  cudaMemcpy(devOutputBiases, outputBiases, OUTPUT_SIZE*sizeof(double), cudaMemcpyHostToDevice);

  double *devPrevOutputBiases;
  cudaMalloc((void**)&devPrevOutputBiases, OUTPUT_SIZE*sizeof(double));
  cudaMemcpy(devPrevOutputBiases, outputBiases, OUTPUT_SIZE*sizeof(double), cudaMemcpyHostToDevice);
  double *devTempOutputBiases;
  cudaMalloc((void**)&devTempOutputBiases, OUTPUT_SIZE*sizeof(double));
  
  
  //training
  /*********************************************************************************************/
  /*
  double *devBiasDelta;
  cudaMalloc((void**)&devBiasDelta, sizeof(double));
  */
  /*********************************************************************************************/

  
  
  printf("Training...");
  
  double iStart = seconds();
  
  for(int epoch = 0; epoch < 1; epoch++){

    for(int k = 0; k < 60000; k++){
    
      feedForwardIH<<<HIDDEN_SIZE, INPUT_SIZE>>>(devInputData, devHiddenNodes, devHiddenWeights, k,devHiddenBiases);
      if ( cudaSuccess != cudaGetLastError() )
	printf( "Error!\n" );
      feedForwardHO<<<OUTPUT_SIZE, HIDDEN_SIZE>>>(devHiddenNodes, devOutputNodes, devOutputWeights, devOutputBiases);
      if ( cudaSuccess != cudaGetLastError() )
	printf( "Error!\n" );
      calcDeltas<<<1, HIDDEN_SIZE>>>(devOutputNodes, devOutputDeltas, devLabelData, k, devHiddenDeltas, devHiddenNodes, devOutputWeights);
      if ( cudaSuccess != cudaGetLastError() )
	printf( "Error!\n" );
      updateInputWeights<<<HIDDEN_SIZE, INPUT_SIZE>>>(devHiddenWeights, devHiddenDeltas, devInputData, k, devPrevHiddenWeights, devTempHiddenWeights);
      if ( cudaSuccess != cudaGetLastError() )
	printf( "Error!\n" );
      updateOutputWeights<<<OUTPUT_SIZE, HIDDEN_SIZE>>>(devOutputWeights, devOutputDeltas, devHiddenNodes, devPrevOutputWeights, devTempOutputWeights);
      if ( cudaSuccess != cudaGetLastError() )
	printf( "Error!\n" );
    
      /*
    updateBiases<<<1, HIDDEN_SIZE>>>(devHiddenBiases, devOutputBiases, devOutputDeltas, devHiddenDeltas, devPrevHiddenBiases, devTempHiddenBiases, devPrevOutputBiases, devTempOutputBiases);
      if ( cudaSuccess != cudaGetLastError() )
	printf( "Error!\n" );
      */
    }
    
  }
  cudaDeviceSynchronize();
  double iElapsed = seconds() - iStart;

  printf("The elapsed time is %f seconds\n", iElapsed);

  /*********************************************************************************************/

  printf("Testing...\n");

  double *testData;
  testData = (double*)malloc(10000 * 28*28 * sizeof(double));
  data.readTestFile(testData);
  

  int *testLabel;
  testLabel = (int*)malloc(10000 * sizeof(int));
  data.readTestLabel(testLabel);

  double *devTestData;
  cudaMalloc((void**)&devTestData, 10000 * 28*28 * sizeof(double));
  cudaMemcpy(devTestData, testData, 10000 * 28*28 * sizeof(double), cudaMemcpyHostToDevice);

  
  
  int *devTestLabel;
  cudaMalloc((void**)&devTestLabel, 10000 * sizeof(int));
  cudaMemcpy(devTestLabel, testLabel, 10000 * sizeof(int), cudaMemcpyHostToDevice);


  int count = 0;
  int *devCount;
  cudaMalloc((void**)&devCount, sizeof(int));
  cudaMemcpy(devCount, &count, sizeof(int), cudaMemcpyHostToDevice);


  
  for(int k = 0; k < 10000; k++){

    feedForwardIH<<<HIDDEN_SIZE, INPUT_SIZE>>>(devTestData, devHiddenNodes, devHiddenWeights, k, devHiddenBiases);
    feedForwardHO<<<OUTPUT_SIZE, HIDDEN_SIZE>>>(devHiddenNodes, devOutputNodes, devOutputWeights, devOutputBiases);
    checkResult<<<1,1>>>(devOutputNodes, devTestLabel, k, devCount);
  }
  
  cudaMemcpy(&count, devCount, sizeof(int), cudaMemcpyDeviceToHost);

  printf("The program predicted %d/10000 numbers correctly\n", count);

  /*********************************************************************************************/
  
  double *result;
  result = (double*)malloc(OUTPUT_SIZE*sizeof(double));


  

  int k = 0;
  
  while(k != -1){
    printf("Enter a data index: ");
    if(scanf("%d", &k) != 1)
      printf("reading error\n");
    if(k == -1)
      break;
    feedForwardIH<<<HIDDEN_SIZE, INPUT_SIZE>>>(devTestData, devHiddenNodes, devHiddenWeights, k, devHiddenBiases);
    feedForwardHO<<<OUTPUT_SIZE, HIDDEN_SIZE>>>(devHiddenNodes, devOutputNodes, devOutputWeights, devOutputBiases);

    cudaMemcpy(result, devOutputNodes, OUTPUT_SIZE*sizeof(double), cudaMemcpyDeviceToHost);

    printf("The expected result is %d\n", testLabel[k]);
    for(int i = 0; i < OUTPUT_SIZE; i++)
      printf("%f, ", result[i]);
    printf("\n");

  }
  
}
