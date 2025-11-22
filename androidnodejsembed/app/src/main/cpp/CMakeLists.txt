cmake_minimum_required(VERSION 3.22.1)

project("androidnodejsembed")

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 添加头文件路径
include_directories(
    ${CMAKE_SOURCE_DIR}/include/node/src
    ${CMAKE_SOURCE_DIR}/include/node/v8
    ${CMAKE_SOURCE_DIR}/include/node/uv
)

# 导入预编译的 libnode.so
add_library(node SHARED IMPORTED)
set_target_properties(node PROPERTIES
    IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libnode.so
)

# 创建你的 JNI 库
add_library(${CMAKE_PROJECT_NAME} SHARED
    native-lib.cpp
)

# 链接库
target_link_libraries(${CMAKE_PROJECT_NAME}
    node
    android
    log
)
