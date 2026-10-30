#include <iostream>
#include <array>
#include <limits>
#include <stdexcept>
#include <string>

#include "factorial_cpu.cpp"

#define ARRAY_LENGTH 5000
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
        factorial = 5;
    }
    std::cout << "Chosen factorial: " << factorial << std::endl;


    try{
        std::array<uint64_t, ARRAY_LENGTH> result = cpu_factorial::calculate_factorial<uint64_t, 10000000, ARRAY_LENGTH>(factorial);

        std::cout << "Output number: ";
        bool start_writing = false;
        for(size_t i = ARRAY_LENGTH ; i > 0 ; i--){
            size_t idx = i - 1;
            if(start_writing){
                std::cout << result[idx];
            }else if(result[idx] != 0){
                start_writing = true;
                std::cout << result[idx];
            }
        }
    }catch(const std::exception e){
        std::cout << "error:\n" << e.what();
    }

    return 0;
}