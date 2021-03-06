#pragma warning(disable:4244)
#pragma warning(disable:4267)
#pragma warning(disable:4819)
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cuda_runtime.h>
#include <DEVICE_LAUNCH_PARAMETERS.h> 
#include <vector>
#include <algorithm>
#include<time.h>
#include <limits>
#include "main.h"
#define prejectionCount 20
#define IX 300
#define IY 300
#define IZ 300
#define m_threshold 125
#define height 768
#define width 1024
typedef unsigned int uint;

__device__ double xcoor(int index)
{
	return -5 +index/30.0;
}
__device__ double ycoor(int index)
{
	return -10 +index/15.0;
}
__device__ double zcoor(int index)
{
	return 15 +index/20.0;
}
__device__	bool outOfRange(int x, int max)
{
	return x < 0 || x >= max;
}

__device__ bool checkRange(cudaProjection projection,double x, double y, double z,uchar* mat, const int cam)
{
	float vec3[3];
	vec3[0]= projection.projMat[0][0]*x+projection.projMat[0][1]*y+projection.projMat[0][2]*z+projection.projMat[0][3];
	vec3[1]= projection.projMat[1][0]*x+projection.projMat[1][1]*y+projection.projMat[1][2]*z+projection.projMat[1][3];
	vec3[2]= projection.projMat[2][0]*x+projection.projMat[2][1]*y+projection.projMat[2][2]*z+projection.projMat[2][3];
	int indX = vec3[1]/vec3[2];
	int indY = vec3[0]/vec3[2];
	if (outOfRange(indX, height) || outOfRange(indY, width))
	{
		return false;
	}
	int k=(int)(*(mat+cam*height*width+(uint)indX*width+(uint)indY));
	return(k>m_threshold);
}

__global__ void getmodel(int* voxel,cudaProjection* projectionList,uchar* mat)
{
	int i = blockIdx.x * blockDim.x + threadIdx.x;  
    int j = blockIdx.y * blockDim.y + threadIdx.y;  
	if(i>=IX||j>=IY)
	{
		return;
	}
	double coorX=xcoor(i);
	double coorY=ycoor(j);
	for(int indexZ=0;indexZ<IZ;indexZ++)
    {
	  	double coorZ = zcoor(indexZ);
	  	for(int n=0;n<prejectionCount;n++)
	  	{
			if(!checkRange(*(projectionList+n),coorX, coorY, coorZ,mat,n))
			{
				*(voxel+i*IY*IZ+j*IZ+indexZ)=0;
				 break;
		    }
		}
	}
}

void cudamodel::compute(int* voxel,cudaProjection* projectionList,uchar* mat[prejectionCount])
{
	int* dev_voxel;
	cudaProjection* dev_projectionList;
	uchar* dev_mat;
	
    cudaMalloc((void**)&dev_voxel, IX*IY*IZ*sizeof(int));
	cudaMalloc((void**)&dev_projectionList, prejectionCount*sizeof(cudaProjection));
	cudaMemcpy(dev_voxel, voxel, IX*IY*IZ*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_projectionList, projectionList, prejectionCount*sizeof(cudaProjection), cudaMemcpyHostToDevice);
	cudaMalloc((void**)&dev_mat,prejectionCount*height*width*sizeof(uchar));
	for(int i=0;i<prejectionCount;i++)
	{
	    cudaMemcpy(dev_mat+height*width*i, mat[i], height*width*sizeof(uchar), cudaMemcpyHostToDevice);
	}
	dim3 numBlocks(16,16); 
	dim3 threadsPerBlock(32,32);
	getmodel<<<numBlocks,threadsPerBlock>>>(dev_voxel,dev_projectionList,dev_mat);
	cudaStreamSynchronize(0);
	//std::cout<<cudaGetLastError()<<"error"<<std::endl;
	cudaMemcpy(voxel, dev_voxel, IX*IY*IZ*sizeof(int), cudaMemcpyDeviceToHost);
	cudaFree(dev_voxel);
	cudaFree(dev_mat);
	cudaFree(dev_projectionList);
}