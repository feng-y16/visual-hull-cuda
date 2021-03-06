#pragma warning(disable:4244)
#pragma warning(disable:4267)
#pragma warning(disable:4819)
#include <vector>
#include <algorithm>
#include<time.h>
#include <limits>
#include <cuda_runtime.h>
#include <DEVICE_LAUNCH_PARAMETERS.h> 
#define prejectionCount 20
#define IX 300
#define IY 300
#define IZ 300
#define height 768
#define width 1024
typedef unsigned char uchar;

__device__ struct cudaProjection
{
public:
	float projMat[3][4];
	cudaProjection(float m1[3][4])
	{
		for(int i=0;i<3;i++)
		{
			for(int j=0;j<4;j++)
			{
			    projMat[i][j]=m1[i][j];
			}
		}
	}
};

class cudamodel
{
public:
	cudamodel(int resX = 100, int resY = 100, int resZ = 100);
	std::vector<cudaProjection> m_projectionList;
	void cudamodel::compute(int* A,cudaProjection* projectionList,uchar* mat[20]);
};