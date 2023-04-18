# A toolchain for compiling with the msvc 19 compiler (visual studio 2015) for the windows 64 bit platform

# Note that you will have to call 
# "%VS140COMNTOOLS%../../VC/vcvarsall.bat" Amd64
# before running cmake when not using the "Visual Studio" generator. 

#file(TO_CMAKE_PATH "$ENV{VS140COMNTOOLS}" vs140comntools)
set(compilerPath "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.35.32215/bin/Hostx64/x64/cl.exe" )

set(CMAKE_CXX_COMPILER "${compilerPath}" CACHE FILEPATH "Microsoft cpp compiler" FORCE)
set(CMAKE_C_COMPILER "${compilerPath}" CACHE FILEPATH "Microsoft c compiler" FORCE)

# /EHsc sadly I can not remember why the /EHsc flag was introduced. (Mabe because of Qt?)
set(CMAKE_CXX_FLAGS "/EHsc /MP" CACHE STRING "C++ compile flags" FORCE)

