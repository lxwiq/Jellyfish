# Règles ProGuard/R8 pour l'optimisation du build Android

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core (pour les fonctionnalités de split install)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Gson (utilisé par de nombreux plugins Flutter)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Conserver les méthodes natives
-keepclasseswithmembernames class * {
    native <methods>;
}

# Conserver les exceptions personnalisées
-keep public class * extends java.lang.Exception

# Media Kit - Conserver les classes nécessaires
-keep class com.alexmercerind.** { *; }
-keep class media.** { *; }

# Conserver les informations de ligne pour le débogage des stack traces
-keepattributes SourceFile,LineNumberTable

# Optimisations supplémentaires
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Conserver les attributs pour la réflexion
-keepattributes *Annotation*,Signature,Exception,InnerClasses,EnclosingMethod

# Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# AndroidX
-dontwarn androidx.**
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

