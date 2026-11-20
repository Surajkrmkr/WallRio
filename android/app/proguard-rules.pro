# Flutter engine references Play Core (deferred components) optionally.
-dontwarn com.google.android.play.core.**

# Keep annotations/signatures needed by Gson/Firebase-style reflection.
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod

# Room instantiates generated *_Impl databases (e.g. WorkManager's) via reflection.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
