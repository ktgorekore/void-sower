# Copyright 2026 Void Sower Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.14)

project(void_sower_library VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include(FetchContent)

# Fetch EnTT ECS library (v3.13.2 header-only release)
FetchContent_Declare(
  entt
  GIT_REPOSITORY https://github.com/skypjack/entt.git
  GIT_TAG        v3.13.2
)
FetchContent_MakeAvailable(entt)

# Fetch Abseil C++ Common Libraries
FetchContent_Declare(
  abseil_cpp
  GIT_REPOSITORY https://github.com/abseil/abseil-cpp.git
  GIT_TAG        20240116.2
)
FetchContent_MakeAvailable(abseil_cpp)

# Security & Compiler Warning Flags
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  add_compile_options(-fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wall -Wextra)
endif()

find_package(Threads REQUIRED)

set(VOID_SOWER_CORE_SOURCES
  "void_sower.cpp"
  "ecs/components.h"
  "ecs/engine.cpp"
  "ecs/systems/ring_buffer.cpp"
  "ecs/systems/spatial_grid.cpp"
  "ecs/systems/movement_system.cpp"
  "ecs/systems/discharge_system.cpp"
  "ecs/systems/match_lifecycle_system.cpp"
  "ecs/systems/bao_cascade_system.cpp"
  "ecs/systems/combat_system.cpp"
  "ecs/systems/wave_generator.cpp"
  "ecs/systems/mcts_solver.cpp"
)

add_library(void_sower SHARED ${VOID_SOWER_CORE_SOURCES})

target_include_directories(void_sower PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(void_sower PRIVATE 
  EnTT::EnTT 
  Threads::Threads 
  absl::inlined_vector 
  absl::flat_hash_set 
  absl::flat_hash_map 
  absl::span
  absl::log
  absl::log_globals
)

set_target_properties(void_sower PROPERTIES
  C_VISIBILITY_PRESET hidden
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
  PUBLIC_HEADER void_sower.h
  OUTPUT_NAME "void_sower"
)

target_compile_definitions(void_sower PUBLIC DART_SHARED_LIB)

# Native binary size optimizations & section pruning
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(void_sower PRIVATE -ffunction-sections -fdata-sections)
  if (APPLE)
    target_link_options(void_sower PRIVATE "-Wl,-dead_strip")
  else()
    target_link_options(void_sower PRIVATE "-Wl,--gc-sections" "-Wl,--exclude-libs,ALL")
  endif()
endif()

# Strict 16 KB page size alignment for Android binaries & native shared targets
if (ANDROID OR UNIX)
  target_link_options(void_sower PRIVATE "-Wl,-z,max-page-size=16384")
endif()

# Interprocedural Optimization (LTO) for Release builds
include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported OUTPUT ipo_error)
if (ipo_supported)
  set_property(TARGET void_sower PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
endif()

# C++ Unit Tests Execution Target
option(BUILD_TESTS "Build native C++ GTest suite" ON)
if (BUILD_TESTS)
  enable_testing()
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
  )
  FetchContent_MakeAvailable(googletest)

  add_executable(void_sower_tests
    "tests/main_test.cpp"
    "tests/combat_rules_test.cpp"
    "tests/ring_buffer_test.cpp"
    "tests/combat_simulation_test.cpp"
    "tests/spatial_grid_test.cpp"
    "tests/wave_generator_test.cpp"
    "tests/ffi_boundary_test.cpp"
    ${VOID_SOWER_CORE_SOURCES}
  )
  target_include_directories(void_sower_tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
  target_link_libraries(void_sower_tests PRIVATE 
    EnTT::EnTT 
    Threads::Threads 
    gtest_main 
    absl::inlined_vector 
    absl::flat_hash_set 
    absl::flat_hash_map 
    absl::span
    absl::log
    absl::log_globals
  )
  add_test(NAME void_sower_tests COMMAND void_sower_tests)
endif()
