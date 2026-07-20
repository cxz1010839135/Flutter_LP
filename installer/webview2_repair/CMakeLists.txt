cmake_minimum_required(VERSION 3.15)
project(LpWebView2Repair LANGUAGES CXX)

add_executable(LpWebView2Repair webview2_repair.cpp)
target_compile_features(LpWebView2Repair PRIVATE cxx_std_17)
target_compile_definitions(LpWebView2Repair PRIVATE UNICODE _UNICODE)

if(MSVC)
  target_compile_options(LpWebView2Repair PRIVATE /W4 /WX /utf-8)
  target_link_options(LpWebView2Repair PRIVATE /SUBSYSTEM:CONSOLE)
endif()
