# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Flutter Platform & Codec Keep Rules
-keepnames class * extends io.flutter.plugin.common.StandardMessageCodec
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Flutter Secure Storage & AndroidX Security
-keep class androidx.security.crypto.** { *; }

# Hive TypeAdapters
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Suppress Play Core warnings for Flutter deferred components
-dontwarn com.google.android.play.core.**
