# A toolchain file to compile the project on Linux with the clang compiler


set(CMAKE_C_COMPILER clang-10 CACHE STRING "C compiler" FORCE)
set(CMAKE_CXX_COMPILER clang++-10 CACHE STRING "C++ compiler" FORCE)

# -fPic: I can not remember why this flag (generate position independent code) was added. Probably to fix link errors with some underlying package.
# I think -fPic is needed when building shared libraries.
set(CMAKE_C_FLAGS "" CACHE STRING "C compile flags" FORCE)    # -fPIC is needed when linking to Qt
set(CMAKE_CXX_FLAGS "" CACHE STRING "C++ compile flags" FORCE)

# -g and -o1 are needed for valgrind. -g adds debug information and -o1 is the optimization level which can not be too high.
set(CMAKE_C_FLAGS_RELEASE "-O3" CACHE STRING "Additional C compile flags when building the Release configuration.")
set(CMAKE_CXX_FLAGS_RELEASE "-O3" CACHE STRING "Additional C++ compile flags when building the Release configuration.")

# -g and -o1 are needed for valgrind. -g adds debug information and -o1 is the optimization level which can not be too high.
set(CMAKE_C_FLAGS_DEBUG "-g -O0" CACHE STRING "Additional C compile flags when building the Debug configuration.")
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0" CACHE STRING "Additional C++ compile flags when building the Debug configuration.")

set(CMAKE_CXX_STANDARD 17 CACHE STRING "Platform independent activation of the required C++ standard.")
