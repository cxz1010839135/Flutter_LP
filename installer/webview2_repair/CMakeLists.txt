cmake_minimum_required(VERSION 3.15)
project(LpWebView2Repair LANGUAGES CXX)

# 静态链接 C/C++ 运行时，避免目标机缺少 VCRUNTIME140_1.dll 导致修复程序无法启动。
# 注意：必须在 add_executable 之前设置，target 创建时才会读取该变量。
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_executable(LpWebView2Repair webview2_repair.cpp)
target_compile_features(LpWebView2Repair PRIVATE cxx_std_17)
target_compile_definitions(LpWebView2Repair PRIVATE UNICODE _UNICODE)

if(MSVC)
  target_compile_options(LpWebView2Repair PRIVATE /W4 /WX /utf-8)
  target_link_options(LpWebView2Repair PRIVATE /SUBSYSTEM:CONSOLE)
endif()
