# Numby ProGuard Rules

# Keep JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep NumbyWrapper class for JNI
-keep class com.numby.NumbyWrapper { *; }
-keep class com.numby.EvaluationResult { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Keep Compose classes
-keep class androidx.compose.** { *; }
