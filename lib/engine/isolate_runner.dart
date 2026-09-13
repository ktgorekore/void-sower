// Copyright 2026 Void Sower Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:isolate';

/// Helper utility for offloading computationally intensive algorithms
/// (e.g. procedural wave generation and MCTS solvability validation)
/// to background isolates to guarantee uncompromised 60/120 FPS UI execution.
class IsolateRunner {
  /// Executes a computation function [callback] with [message] on a dedicated background isolate.
  static Future<R> run<M, R>(
    FutureOr<R> Function(M message) callback,
    M message,
  ) async {
    return Isolate.run(() => callback(message));
  }
}
