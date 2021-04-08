

set(compilerPath "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/Llvm/bin/clang-cl.exe" )

set(CMAKE_CXX_COMPILER "${compilerPath}" CACHE FILEPATH "Microsoft cpp compiler" FORCE)
set(CMAKE_C_COMPILER "${compilerPath}" CACHE FILEPATH "Microsoft c compiler" FORCE)
set(CMAKE_LINKER "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/Llvm/bin/lld-link.exe" CACHE FILEPATH " " FORCE)
#set(CMAKE_C_COMPILER_ID "Clang" CACHE STRING " " FORCE)
#set(CMAKE_CXX_COMPILER_ID "Clang" CACHE STRING " " FORCE)
#set(CMAKE_SYSTEM_NAME "Generic" CACHE STRING " " FORCE)

set(CMAKE_CXX_FLAGS "-m64 /EHsc" CACHE STRING "C++ compile flags" FORCE)
set(CMAKE_C_FLAGS "-m64" CACHE STRING "C++ compile flags" FORCE)