#include <array>
#include <limits>
#include <stdexcept>

namespace cpu_factorial{

//function for static assert
constexpr bool is_power_of_10(int n) {
    if (n < 1) return false;

    while (n % 10 == 0) {
        n /= 10;
    }

    return n == 1;
}

template <typename T, size_t BASE, size_t ARRAY_LENGTH>
std::array<T, ARRAY_LENGTH> calculate_factorial(size_t factorial){
    //compilation only assert
    //checks if biggest number and carry can fit inside given type
    static_assert((BASE * 2 - 1) < std::numeric_limits<T>::max(), "Type is to small.");
    //checks if base is power of 10
    static_assert(is_power_of_10(BASE), "BASE must be power of 10.");

    std::array<T, ARRAY_LENGTH> number;
    number[0] = 1;
    for(size_t i = 1 ; i < ARRAY_LENGTH ; i++){
        number[i] = 0;
    }

    for(size_t z = 2 ; z <= factorial ; z++){
        T carry = 0;
        for(size_t i = 0 ; i < ARRAY_LENGTH ; i++){
            T temp = number[i] * z + carry;
            number[i] = temp % BASE;
            carry = temp / BASE;
        }
        //checking overflow of number array
        if(carry != 0){
            throw std::overflow_error("Carry overflowed. Chosen factorial is to big.");
        }
    }

    return number;
}
}