

# This needs to be done as early as possible,
set( CPF_MINIMUM_CMAKE_VERSION 3.12.1)
cmake_minimum_required(VERSION ${CPF_MINIMUM_CMAKE_VERSION})
cmake_policy(SET CMP0007 NEW) # Do not ignore empty list elements
cmake_policy(SET CMP0011 NEW) # Policy settings from included files do not affect the including context.
cmake_policy(SET CMP0071 NEW)

# Enable short includes for cpf modules
list(APPEND CMAKE_MODULE_PATH 
    "${CMAKE_SOURCE_DIR}/CPFCMake/Functions"
    "${CMAKE_SOURCE_DIR}/CPFCMake/Variables"
)

include(cpfAddPackages)             # This is always needed in the root lists file.
include("${CMAKE_TOOLCHAIN_FILE}")  # Make sure the compiler is set before the project call.

