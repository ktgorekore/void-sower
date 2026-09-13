#!/usr/bin/env python3
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

import os
import sys
import subprocess
import argparse

def get_staged_files():
    """Retrieves a list of all currently staged files in git."""
    try:
        result = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=d"],
            capture_output=True, text=True, check=True
        )
        return [f.strip() for f in result.stdout.splitlines() if f.strip()]
    except subprocess.CalledProcessError:
        print("[-] Error: Failed to fetch staged files from Git.")
        sys.exit(1)

def get_all_source_files():
    """Retrieves all C++ and Dart source files in the repository."""
    files = []
    search_dirs = ["src", "lib", "test"]
    for d in search_dirs:
        if not os.path.exists(d):
            continue
        for root, _, filenames in os.walk(d):
            # Skip build directories
            if "build" in root or ".dart_tool" in root:
                continue
            for f in filenames:
                if f.endswith(('.cpp', '.h', '.cc', '.hpp', '.dart')):
                    # Skip generated ffi bindings from manual formatting checks
                    if f.endswith('_bindings_generated.dart'):
                        continue
                    files.append(os.path.join(root, f))
    return files

def check_cpp_format(filepath):
    """Checks formatting using clang-format."""
    if not os.path.exists(filepath):
        return True
    try:
        result = subprocess.run(
            ["clang-format", "--style=Google", "-dry-run", "--Werror", filepath],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"[!] Formatting Error (C++): {filepath} violates Google C++ Style Guide.")
            return False
        return True
    except FileNotFoundError:
        print("[-] Error: 'clang-format' tool not found. Please install it.")
        sys.exit(1)

def check_dart_format(filepath):
    """Checks formatting using dart format."""
    if not os.path.exists(filepath):
        return True
    try:
        result = subprocess.run(
            ["dart", "format", "--set-exit-if-changed", filepath],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"[!] Formatting Error (Dart): {filepath} is not properly formatted.")
            return False
        return True
    except FileNotFoundError:
        print("[-] Error: 'dart' SDK command line tool not found. Please install it.")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Audit source code formatting.")
    parser.add_argument("--all", action="store_true", help="Audit all repository source files instead of staged files.")
    args = parser.parse_args()

    if args.all:
        files_to_check = get_all_source_files()
        print(f"[*] Auditing {len(files_to_check)} total source files across repository...")
    else:
        files_to_check = get_staged_files()
        if not files_to_check:
            print("[+] No staged files found to verify.")
            sys.exit(0)
        print(f"[*] Auditing {len(files_to_check)} staged files for style compliance...")

    failed = False
    for file in files_to_check:
        if file.endswith(('.cpp', '.h', '.cc', '.hpp')):
            if not check_cpp_format(file):
                failed = True
        elif file.endswith('.dart'):
            if not check_dart_format(file):
                failed = True

    if failed:
        print("\n[-] Code verification failed. Run formatting tools before committing.")
        sys.exit(1)
    
    print("[+] Formatting checks passed successfully. Style matches criteria.")
    sys.exit(0)

if __name__ == "__main__":
    main()
