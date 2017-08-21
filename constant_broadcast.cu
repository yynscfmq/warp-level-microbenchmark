#include <stdlib.h>
#include <stdio.h>
#include <cuda_runtime.h>
#define DATATYPE int
#define MEMSIZE 1024
#define REP 128
#define conflictnum 32

__constant__ int d_array_m1[MEMSIZE];
__constant__ int d_array_m2[MEMSIZE];
__global__ void constant_broadcast(double *time,DATATYPE *out,int its)
{
	DATATYPE p,q=(threadIdx.x/conflictnum);
//	DATATYPE p,q=(threadIdx.x/conflictnum*conflictnum);
	double time_tmp=0.0;
	unsigned int start_time=0,stop_time=0;
	unsigned int i,j;
	for (i=0;i<its;i++)
	{
		__syncthreads();
		start_time=clock();
#pragma unroll
		for (j=0;j<REP;j++)
		{
			p=d_array_m1[q];
			q=d_array_m2[p];
		}
		stop_time=clock();
		time_tmp+=(stop_time-start_time);
	}
	time_tmp=time_tmp/REP/its;
	out[blockDim.x*blockIdx.x+threadIdx.x] = p+q;
	time[blockDim.x*blockIdx.x+threadIdx.x] = time_tmp;
}

int main_test(int blocks,int threads,DATATYPE *h_in1,DATATYPE *h_in2)
{
	int its=30;
	//int blocks=1,threads=32;
	cudaMemcpyToSymbol(d_array_m1,h_in1,MEMSIZE*sizeof(int),0,cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(d_array_m2,h_in2,MEMSIZE*sizeof(int),0,cudaMemcpyHostToDevice);
	double *h_time,*d_time;
	DATATYPE *d_out;
	h_time=(double*)malloc(sizeof(double)*blocks*threads);
	cudaMalloc((void**)&d_time,sizeof(double)*blocks*threads);
	cudaMalloc((void**)&d_out,sizeof(DATATYPE)*blocks*threads);

	constant_broadcast<<<blocks,threads>>>(d_time,d_out,its);
	cudaMemcpy(h_time,d_time,sizeof(double)*blocks*threads,cudaMemcpyDeviceToHost);
	double avert=0.0,maxt=0.0,mint=99999.9;
	int nn=0;
	for (int i=0;i<blocks;i++)
	{
		for (int j=0;j<threads;j+=32)
		{
			avert+=h_time[i*threads+j];
			nn++;
			if (maxt<h_time[i*threads+j])
			{
				maxt=h_time[i*threads+j];
			}
			if (mint>h_time[i*threads+j])
			{
				mint=h_time[i*threads+j];
			}
		}
	}
	avert/=nn;
	printf("%d\t%d\t\t%f\t%f\t%f\n", blocks,threads,avert,mint,maxt);
	cudaFree(d_time);
	cudaFree(d_out);
	free(h_time);
	return 0;
}
void init_order(DATATYPE *a,int n)
{
	for (int i=0;i<n;i++)
	{
		a[i]=i;
	}
}

int main()
{
	DATATYPE *h_in1;
	h_in1=(DATATYPE*)malloc(sizeof(DATATYPE)*MEMSIZE);

	init_order(h_in1,MEMSIZE);


/*
	for (int i=0;i<MEMSIZE;i+=32)
	{
		for (int j=0;j<32;j++)
		{
			printf("%d\t",h_in3[i+j]);
		}
		printf("\n");
	}
*/

	printf("blocks\t threads\t aver \t min \t max \t(clocks)\n");

	//main_test(1,32,h_in1,h_in1,1);
	//main_test(1,32,h_in2,h_in2,2);
	//main_test(1,32,h_in3,h_in3,3);
	//main_test(1,512,h_in1,h_in1,1);
	//main_test(1,512,h_in2,h_in2,2);
	//main_test(1,512,h_in3,h_in3,3);



/*
	for (int i=0;i<=1;i+=32)
	{
		int blocks=i;
		if (i==0)
		{
			blocks=1;
		}
		for (int j=0;j<=512;j+=32)
		{
			int threads=j;
			if (j==0)
			{
				threads=1;
			}
			main_test(blocks,threads,h_in1,h_in1);
		}
	}
*/





	for (int i=0;i<=1024;i+=32)
	{
		int blocks=i;
		if (i==0)
		{
			blocks=1;
		}
		for (int j=1024;j<=1024;j+=32)
		{
			int threads=j;
			if (j==0)
			{
				threads=1;
			}
			main_test(blocks,threads,h_in1,h_in1);
		}
	}



	free(h_in1);

	return 0;
}
