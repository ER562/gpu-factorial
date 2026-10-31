#include <array>
#include <limits>
#include <cstdint>
#include <stdexcept>
#include <cuda_runtime.h>
#include <iostream> //to delete
#include "factorial_gpu.cuh"

namespace gpu_factorial{

//function for static assert
constexpr bool is_power_of_10(int n) {
    if (n < 1) return false;

    while (n % 10 == 0) {
        n /= 10;
    }

    return n == 1;
}

template <typename T, size_t BASE, size_t ARRAY_LENGTH, size_t RESERVATION_LEN>
__global__ void compute(T *result, unsigned long long *factorial, int *error){
    if(threadIdx.x < ARRAY_LENGTH){ //this is neccesary when ARRAY_LENGTH != number_of_threads
        //creating shared variable and initializing it
        __shared__ T carry[ARRAY_LENGTH + 1];   //this array is longer to save runtime on boundary checks
        if(threadIdx.x == 0){
            carry[threadIdx.x] = 0;
            carry[ARRAY_LENGTH] = 0;
        }else{
            carry[threadIdx.x] = 0;
        }

        //computing
        __shared__ size_t count_to;
        __shared__ size_t current_count;
        if(threadIdx.x == 0){
            count_to = *factorial;
            current_count = 2;
        }

        while(current_count <= count_to){
            carry[threadIdx.x] = 0;

            __shared__ int not_zeros;
            if(threadIdx.x == 0){
                not_zeros = 0;
            }
            __syncthreads();

            result[threadIdx.x] = result[threadIdx.x] * current_count;
            while(not_zeros == 0){   //propagate carry through entire array
                T temp = result[threadIdx.x] + carry[threadIdx.x];
                result[threadIdx.x] = temp % BASE;
                __syncthreads();    //modyfying another thread's carry
                carry[threadIdx.x + 1] = temp / BASE;
                if(threadIdx.x == 0){
                    not_zeros = 1;
                }
                __syncthreads();
                if(carry[threadIdx.x] != 0){
                    atomicExch(&not_zeros, 0);
                }
                __syncthreads();
            }
            if(threadIdx.x == 0){
                current_count++;
            }
            __syncthreads();
        }
        if(threadIdx.x == 0){
            if(carry[ARRAY_LENGTH] != 0){   //checking if overflow occured
                *error = 1;
            }
        }
        return;
    }
}

template <typename T, size_t BASE, size_t ARRAY_LENGTH>
std::array<T, ARRAY_LENGTH> calculate_factorial(size_t factorial){
    //compilation only assert
    //checks if biggest number and carry can fit inside given type
    static_assert((BASE * 2 - 1) < std::numeric_limits<T>::max(), "Type is to small.");
    //checks if base is power of 10
    static_assert(is_power_of_10(BASE), "BASE must be power of 10.");

    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    long long number_of_threads = prop.maxThreadsPerBlock;
    if(prop.maxThreadsPerBlock < ARRAY_LENGTH){
        throw std::range_error("ARRAY_LENGTH canno't be longer than number ov available threads in blocks.");
    }

    if(ARRAY_LENGTH > number_of_threads){
        throw std::overflow_error("Length of an array canno't exceede number of possible threads.");
    }

    T *cuda_ptr;    //array for stroing results
    std::array<T, ARRAY_LENGTH> result;
    for(int i = 1 ; i < ARRAY_LENGTH ; i++){
        result[i] = 0;
    }
    result[0] = 1;
    cudaMalloc(reinterpret_cast<void**>(&cuda_ptr), sizeof(T) * ARRAY_LENGTH);
    cudaMemcpy(cuda_ptr, result.data(), sizeof(T) * ARRAY_LENGTH, cudaMemcpyHostToDevice);

    unsigned long long *cuda_factorial; //maximum number of loops
    cudaMalloc(reinterpret_cast<void**>(&cuda_factorial), sizeof(unsigned long long));
    cudaMemcpy(cuda_factorial, &factorial, sizeof(unsigned long long), cudaMemcpyHostToDevice);

    int *cuda_error;
    int initial_cuda_error = 0;
    cudaMalloc(reinterpret_cast<void**>(&cuda_error), sizeof(int));
    cudaMemcpy(cuda_error, &initial_cuda_error, sizeof(int), cudaMemcpyHostToDevice);

    cudaDeviceSynchronize();

    compute<T, BASE, ARRAY_LENGTH, 3><<<1, ARRAY_LENGTH>>>(cuda_ptr, cuda_factorial, cuda_error);

    cudaDeviceSynchronize();

    cudaMemcpy(result.data(), cuda_ptr, sizeof(T) * ARRAY_LENGTH, cudaMemcpyDeviceToHost);
    int error = 1;
    cudaMemcpy(&error, cuda_error, sizeof(int), cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();

    if(error != 0){
        throw std::overflow_error("Overflow occured.");
    }

    cudaFree(cuda_ptr);
    cudaFree(cuda_factorial);
    cudaFree(cuda_error);
    return result;
}

template std::array<uint32_t, 1024> gpu_factorial::calculate_factorial<uint32_t, 1000000, 1024>(size_t);

}