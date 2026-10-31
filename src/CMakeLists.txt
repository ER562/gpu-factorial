add_executable(factorial_app
    main.cpp
    factorial_cpu.cpp
    factorial_gpu.cu
)

target_include_directories(factorial_app PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

set_target_properties(factorial_app PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
)

target_compile_options(factorial_app PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:/Zc:preprocessor>
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/Zc:preprocessor>
)