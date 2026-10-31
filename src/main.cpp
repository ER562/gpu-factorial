#include <iostream>
#include <array>
#include <limits>
#include <stdexcept>
#include <string>
#include <chrono>

#include "factorial_cpu.cpp"
#include "factorial_gpu.cuh"

constexpr size_t array_len = 1024;
int main(int argc, char *argv[]){

    size_t factorial;
    if(argc > 2){
        std::cout << "Too much input arguments.";
        return 1;
    }else if(argc == 2){
        try{
            factorial = std::stoi(argv[1]);
        }catch(const std::exception e){
            std::cout << "error:\n" << e.what();
            return 1;
        }
    }else{
        factorial = 20;
    }
    std::cout << "Chosen factorial: " << factorial << std::endl << std::endl;

    std::chrono::steady_clock::time_point start;
    std::chrono::steady_clock::time_point stop;
    std::chrono::nanoseconds time_cpu;
    std::chrono::nanoseconds time_gpu;
    std::array<uint32_t, array_len> result_cpu;
    std::array<uint32_t, array_len> result_gpu;
    bool error_cpu = false;
    bool error_gpu = false;

    //cpu
    try{
        start = std::chrono::high_resolution_clock::now();
        result_cpu = cpu_factorial::calculate_factorial<uint32_t, 1000000, array_len>(factorial);
        stop = std::chrono::high_resolution_clock::now();
        time_cpu = stop - start;

        std::cout << "CPU output number: ";
        bool start_writing = false;
        for(size_t i = array_len ; i > 0 ; i--){
            size_t idx = i - 1;
            if(start_writing){
                std::cout << result_cpu[idx];
            }else if(result_cpu[idx] != 0){
                start_writing = true;
                std::cout << result_cpu[idx];
            }
        }
        std::cout << std::endl;
    }catch(const std::exception e){
        std::cout << "CPU error: " << e.what() << std::endl;
        error_cpu = true;
    }

    //gpu
    std::cout << std::endl;
    try{
        start = std::chrono::high_resolution_clock::now();
        result_gpu = gpu_factorial::calculate_factorial<uint32_t, 1000000, array_len>(factorial);
        stop = std::chrono::high_resolution_clock::now();
        time_gpu = stop - start;

        std::cout << "GPU output number: ";
        bool start_writing = false;
        for(size_t i = array_len ; i > 0 ; i--){
            size_t idx = i - 1;
            if(start_writing){
                std::cout << result_gpu[idx];
            }else if(result_cpu[idx] != 0){
                start_writing = true;
                std::cout << result_gpu[idx];
            }
        }
        std::cout << std::endl;
    }catch(const std::exception e){
        std::cout << "GPU error: " << e.what() << std::endl;
        error_gpu = true;
    }

    //overall results
    bool zero_errors = true;
    for(int i = 0 ; i < array_len ; i++){
        if(result_cpu[i] != result_gpu[i]){
            zero_errors = false;
        }
    }

    std::cout << std::endl;
    if(error_cpu){
        std::cout << "CPU function threw exception.\n";
    }else{
        std::cout << "CPU execution time: " << std::chrono::duration_cast<std::chrono::microseconds>(time_cpu).count() << std::endl;
    }
    std::cout << std::endl;
    if(error_gpu){
        std::cout << "GPU function threw exception.\n";
    }else{
        std::cout << "GPU execution time: " << std::chrono::duration_cast<std::chrono::microseconds>(time_gpu).count() << std::endl;
    }
    std::cout << std::endl;
    if(zero_errors){
        std::cout << "Answers are the same.\n";
    }else{
        std::cout << "Answers are diffrent\n";
    }

    return 0;
}