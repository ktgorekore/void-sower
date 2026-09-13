/*
 * Copyright 2026 Void Sower Authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';

void main() {
  runApp(const VoidSowerApp());
}

/// Root widget for the Void Sower application.
class VoidSowerApp extends StatelessWidget {
  /// Creates the [VoidSowerApp].
  const VoidSowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Sower: Bao Orbital Batteries',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF030712),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // Solar cyan
          secondary: Color(0xFFF59E0B), // Battery amber
          surface: Color(0xFF0F172A), // Deep void
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'VOID SOWER: BAO ORBITAL BATTERIES',
            style: TextStyle(
              color: Color(0xFF06B6D4),
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
