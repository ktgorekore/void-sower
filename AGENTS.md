<!--
  Copyright 2026 Void Sower Authors.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# 🤖 AGENTS.md — Contributor & Autonomous Agent Guidelines

Welcome to the **Void Sower** repository. This document defines operating standards, coding guidelines, build system workflows, performance rules, and git hygiene procedures for both autonomous AI agents and human contributors, synthesized from our production repositories (`cognitas-trading`, `oware-2048`, and `hotpathcpp`).

---

## 1. Role & Core Stack
You are an expert game engineering agent specialized in performance-critical hybrid applications:
- **Frontend UI Layer:** Flutter 3.x / Dart FFI Engine (Android mobile first, portrait orientation).
- **Core Game Logic Backend:** Modern C++ (C++17) with EnTT Entity-Component-System (ECS).
- **Build System Orchestrator:** Native CMake integrated via Android Gradle `externalNativeBuild`.
- **Mathematical Framework:** Bao la Kiswahili count-and-capture rules & backward-play program inversion.
- **High-Performance Primitives:** Cache-line aligned (`alignas(64)`) power-of-two ring buffers with bitwise index masking (`& 0x0F`), zero per-frame allocation, and Abseil data structures.

---

## 2. General Engineering Principles

1. **Deep Understanding First:** Treat each change as a deep exercise. You must fully understand how the current system works before making modifications, think about best practices, and implement changes effectively and elegantly rather than applying surface-level patches.
2. **Production-Grade Code:** This is production-grade software, not an MVP or prototype. Do not leave `TODO` comments, placeholder code, or "future work" notes. Design and implement the most robust, well-structured, and highly optimized solution from the outset.
3. **Minimal Changes:** All code modifications must be minimal and necessary. Do not refactor unrelated code.
4. **Code Reuse:** Before writing new algorithms or utilities, always inspect existing implementations in the workspace (such as our high-performance ring buffer patterns in `cognitas-trading` and solver architectures in `oware-2048`).
5. **No Placeholders:** Either implement the fix/feature fully or, if the scope is unclear, ask the user for confirmation before proceeding.

---

## 3. Strict Compilation, Licensing & Build System Rules

1. **Licensing (Verbatim Apache 2.0 Header):** Every code file (C++, Dart, CMake, Python, Gradle, etc.) MUST start with the verbatim Apache 2.0 License header attributed to **Void Sower Authors**.
2. **Android 16 KB Memory Page Size Alignment:** All native C/C++ libraries must be explicitly structured to target a 16 KB memory page size alignment. Append `-Wl,-z,max-page-size=16384` to all CMake linker flags.
3. **Flat C-Style ABI (`extern "C"`):** Ensure all native endpoints resolve natively via flat C-style Application Binary Interfaces (`extern "C"`) in `src/void_sower.h` to map flawlessly to Dart FFI pointers without JNI overhead.
4. **Preprocessor Header Guards:** Do NOT use `#pragma once`. Use classic preprocessor header guards (`#ifndef VOID_SOWER_FILE_H_`, `#define ...`, `#endif`) for all C++ headers.
5. **Single-Line Nested Namespaces:** Use C++17 single-line nested namespace syntax (e.g., `namespace void_sower::ecs { ... }`) for all C++ namespaces. Do NOT use multi-line nested namespace blocks.
6. **Abseil Data Structures:** Prefer Abseil data structures (`absl::flat_hash_map`, `absl::flat_hash_set`, `absl::InlinedVector`, `absl::Span`, etc.) over standard STL containers for high-performance memory layout, cache efficiency, and bounds checking.
7. **Compiler Security Flags:** Maintain `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`, `-Wall`, and `-Wextra` on all C/C++ targets.
8. **No C++ Exceptions across FFI:** The use of C++ exceptions across FFI boundaries is strictly forbidden. Functions should return error/status codes or POD structs.

---

## 4. High-Performance Ring Buffer & Data-Oriented Architecture

Drawing directly from our low-latency infrastructure in `cognitas-trading`:
1. **Power-of-Two Capacity & Bitwise Masking:** All ring buffers (including the 16-bay dreadnought capacitor ring) MUST have a power-of-two capacity ($N = 2^k$). Index arithmetic must use bitwise masking:
   ```cpp
   index = (current + direction + capacity) & (capacity - 1);
   ```
   Never use runtime truncated modulo division (`%`) on critical simulation hot paths.
2. **Cache-Line Alignment:** Align memory-critical buffers and combat state structures to 64 bytes (`alignas(64)`) to eliminate false sharing and match ARM L1 cache line prefetching.
3. **Zero Dynamic Memory Allocation on Hot Paths:** All simulation state updates, spatial grid bucketing, particle lance allocations, and flak bursts must operate on pre-allocated contiguous pools or static arrays. Zero runtime `malloc`/`new` calls during active combat.
4. **Variable Scope:** Prefer C++17 `if` statements with initializers (`if (auto x = foo(); x.valid())`) to keep variable scope as tight as possible.

---

## 5. Dart / Flutter UI & FFI Boundary Standards

1. **Google Dart Style Guide:** All Dart code must strictly follow the official Google Dart Style Guide and pass `flutter analyze` with zero warnings.
2. **Zero-Copy Memory Pointer Caching:** Pre-allocate fixed native struct pointers (`calloc`) once during `FfiVoidSowerEngine` initialization and reuse them for per-frame polling. Eliminate per-frame `calloc`/`free` churn.
3. **Background Isolate Offloading:** Heavy procedural level generation, MCTS solvability validation, and long-range targeting calculations must execute in background isolates (`IsolateRunner`) to guarantee an uncompromised 60/120 FPS UI thread.
4. **Ergonomic One-Thumb Mobile Viewport:** All interactive controls (radial bay selection, namua flick injection, lateral platform slider) must reside strictly within the lower 30% primary thumb command arc, maintaining $\ge 48 \times 48\text{ dp}$ touch bounds.
5. **Clean Uninstall Hygiene:** Configure `android:allowBackup="false"` and author `data_extraction_rules.xml` so local guest progress is wiped upon uninstall without silent Google Drive backup restoration.

---

## 6. Code Style, Documentation & Quality Verification

1. **Strict Style Guide Adherence:** All C++ code MUST strictly adhere to the official **Google C++ Style Guide** and all Dart code MUST strictly adhere to the official **Google Dart Style Guide** without exception. This encompasses naming conventions, class design, memory management, comment styles, and structural layouts.
2. **Doxygen & DartDoc Documentation:** All public functions, classes, and structs MUST contain comprehensive, explicit API documentation using Doxygen style tags (`/** ... */` with `@brief`, `@param`, `@return`) for C++ and official DartDoc markdown format (`/// ...`) for Dart.
3. **Mandatory Code Formatting Prior to Committing:** Always format modified files prior to performing any staging or git commit operations:
   - C++: `clang-format -style=Google -i <file>`
   - Dart: `dart format <file>`
   - Zero-warning requirement: Must pass `flutter analyze` with 0 issues and C++ builds with `-Wall -Wextra -Werror` compliance.
4. **Unit Testing:** All new code blocks MUST be accompanied by comprehensive, self-documenting unit tests verifying edge cases, boundary wrapping, and operational limits (Google Test for C++, `flutter test` for Dart).
5. **Frequent, Verified Commits:** Stage and commit your changes to git frequently and systematically after each verified milestone, test suite pass, and formatting cycle. Do not accumulate large batches of uncommitted changes.

---

## 7. Git Version Control Constraints

1. **Atomic Commits:** Changes must be systematically split into small, atomic, and self-contained commits.
2. **Semantic Messages:** Use strict semantic commit messages (e.g., `feat(engine):`, `fix(ffi):`, `test(ring_buffer):`, `docs(agents):`).
3. **No Overrides:** NEVER use `git commit --amend` to rewrite or append onto existing pushed or local commits.
4. **Mandatory Commits:** All changes MUST be committed to git.
5. **What NEVER Belongs in Git:**
   - Binary build outputs (`build/`, `.gradle/`, `.dart_tool/`, `src/build/`).
   - Keystores, signing secrets, or credentials (`*.jks`, `key.properties`).
   - Master video renders, screenrecord dumps, or uncompressed audio scratch files.
