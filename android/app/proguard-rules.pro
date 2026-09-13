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

# ==============================================================================
# VOID SOWER RELEASE PROGUARD & R8 SECURITY CONFIGURATION
# ==============================================================================

# Flutter & Dart Framework Runtime Preservation
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep public class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
-keep public class * extends io.flutter.embedding.android.FlutterActivity
-keep class io.flutter.embedding.engine.plugins.** { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }

# Dart FFI & Native C++ Symbol Boundary Preservation
# Preserves JNI and C-ABI export names for dynamic resolution via ffi.DynamicLibrary.open("libvoid_sower.so")
-keepclasseswithmembernames class * {
    native <methods>;
}

-keep class com.voidsower.app.** { *; }

# In-App Purchases & Google Play Billing Library
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }

# Google Mobile Ads (AdMob) SDK & Mediation
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.mediation.** { *; }
-keep public class com.google.android.gms.ads.initialization.OnInitializationCompleteListener

# AndroidX App Startup, WorkManager & Room
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-dontwarn androidx.work.**

# Google Play Games Services & Identity
-keep class com.google.android.gms.games.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Firebase Crashlytics & Analytics
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**
-keep class com.google.firebase.analytics.** { *; }

# Audio Engine (Audioplayers)
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# General Optimization & Warning Suppression
-dontwarn io.flutter.embedding.android.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe
