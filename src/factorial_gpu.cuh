#pragma once

#include <array>
#include <cstddef>
#include <cstdint>

namespace gpu_factorial {

template <typename T, size_t BASE, size_t ARRAY_LENGTH>
std::array<T, ARRAY_LENGTH> calculate_factorial(size_t factorial);

}