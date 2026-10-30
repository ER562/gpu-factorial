#include <array>
#include <stdexcept>

namespace gpu_factorial{

template <typename T, size_t BASE, size_t ARRAY_LENGTH, size_t RESERVATION_LEN>
__global__ void compute(T *result, size_t count, size_t factorial, int error){
    if(threadIdx.x < ARRAY_LENGTH){ //this is neccesary when ARRAY_LENGTH != number_of_threads
        //operation on blocks
        //creating shared variable and initializing it
        __shared__ T block_result[ARRAY_LENGTH];
        __shared__ T carry[ARRAY_LENGTH + 1];   //this array is longer to save runtime on boundary checks
        if(threadIdx.x = 0){
            block_result[threadIdx.x] = 1;
            carry[threadIdx.x] = 0;
            carry[ARRAY_LENGTH] = 0;
        }else{
            block_result[idx] = 0;
            carry[threadIdx.x] = 0;
        }

        //distributing tasks and computing
        __shared__ size_t count_to;
        __shared__ size_t current_count;
        if(threadIdx.x == 0){
            count_to = 2;
            current_count = 2;
        }
        while(1){
            if(threadIdx.x == 0){
                if(current_count == count_to){
                    current_count = atomicAdd(count, RESERVATION_LEN);
                    count_to = current_count + RESERVATION_LEN;
                }
            }
            __syncthreads();

            __shared__ short not_zeros;
            block_result[threadIdx.x] = block_result[threadIdx.x] * current_count;
            while(not_zeros == 0){   //propagate carry through entire array
                __syncthreads();
                T temp = block_result[threadIdx.x] + carry[threadIdx.x];
                block_result[threadIdx.x] = temp % BASE;
                carry[threadIdx.x + 1] = temp / BASE;
                not_zeros = 1;
                __syncthreads();
                if(carry[threadIdx.x != 0]){
                    atomicExch(&not_zeros, 0);
                }
                __syncthreads();
            }
        }
        if(threadIdx.x == 0){   //checking if overflow occured
            if(carry[ARRAY_LENGTH] != 0){
                error = 1;
                return;
            }
        }
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
    long long number_of_blocks = prop.maxBlocksPerMultiProcessor;
    if(prop.maxThreadsPerBlock < ARRAY_LENGTH){
        throw std::range_error("ARRAY_LENGTH canno't be longer than number ov available threads in blocks.");
    }

    T *cuda_ptr;    //array for stroing results
    cudaMalloc(cuda_ptr, sizeof(T) * ARRAY_LENGTH);
    size_t *cuda_counter;    //variable for task coordination
    cudaMalloc(cuda_counter, sizeof(size_t));
    cudaMemcpy(cuda_counter, &2, sizeof(size_t), cudaMemcpyHostToDevice);
    size_t *cuda_factorial; //maximum number of loops
    cudaMalloc(cuda_factorial, sizeof(size_t));
    cudaMemcpy(cuda_factorial, &factorial, sizeof(size_t), cudaMemcpyHostToDevice);
    int * cuda_error;
    cudaMalloc(cuda_error, sizeof(int));
    cudaMemcpy(cuda_error, &1, sizeof(int), cudaMemcpyHostToDevice);
    cudaDeviceSynchronize();

    compute<T, BASE, ARRAY_LENGTH, 15><<<number_of_blocks, number_of_threads>>>(cuda_ptr, cuda_counter, cuda_factorial, cuda_error);  //this must be trimed down

    cudaDeviceSynchronize();
    std::array<T, ARRAY_LENGTH> result; //this could be moved before synchronize to execute in the same time as compute fun
    cudaMemcpy(result.data(), cuda_ptr, ARRAY_LENGTH, cudaMemcpyDeviceToHost);
    int error;
    cudaMemcpy(&error, cuda_error, 1, cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();

    if(error != 0){
        throw std::overflow_error("Overflow occured.");
    }

    cudaFree(cuda_ptr);
    cudaFree(cuda_counter);
    cudaFree(cuda_factorial);
    cudaFree(cuda_error);
    return result;
}
}