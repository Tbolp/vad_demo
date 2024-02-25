cmake_minimum_required(VERSION 3.18)

project(vad_demo)

add_library(vad_demo SHARED ../../windows/runner/silero_vad.cpp)

set(ncnn_DIR "ncnn-20240102-android/${ANDROID_ABI}/lib/cmake/ncnn")
#C:\Users\Tbolp\Documents\projects\vad_demo\android\app\ncnn-20240102-android\x86\lib\cmake\ncnn\ncnn.cmake
find_package(ncnn CONFIG REQUIRED PATHS)

target_link_libraries(vad_demo PRIVATE ncnn)