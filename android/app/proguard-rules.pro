#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter engine references Play Core (deferred components) optionally.
-dontwarn com.google.android.play.core.**

# Keep annotations/signatures needed by Gson/Firebase-style reflection.
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod
