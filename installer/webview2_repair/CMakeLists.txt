cmake_minimum_required(VERSION 3.15)
project(LpWebView2Repair LANGUAGES CXX)

add_executable(LpWebView2Repair webview2_repair.cpp)
target_compile_features(LpWebView2Repair PRIVATE cxx_std_17)
target_compile_definitions(LpWebView2Repair PRIVATE UNICODE _UNICODE)

if(MSVC)
  target_compile_options(LpWebView2Repair PRIVATE /W4 /WX /utf-8)
  # 静态链接 C/C++ 运行时，避免目标机缺少 VCRUNTIME140.dll 导致修复程序无法启动。
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")
  target_link_options(LpWebView2Repair PRIVATE /SUBSYSTEM:CONSOLE)
endif()
